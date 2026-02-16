//==============================================================================
// Module: aes_ctr_encrypt
// Description: AES-128 CTR mode encryption
//              Encrypts counter block to generate keystream
//              Ciphertext = Plaintext XOR Keystream
//
// Author: FPGA Secure Telemetry System
// Target: Xilinx Vivado (7-series FPGAs)
//==============================================================================

module aes_ctr_encrypt (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [127:0] session_key,
    input wire [31:0] counter,
    input wire [127:0] plaintext,
    output reg [127:0] ciphertext,
    output reg done
);

    // State machine states
    localparam IDLE = 2'b00;
    localparam ENCRYPT_COUNTER = 2'b01;
    localparam XOR_DATA = 2'b10;
    localparam FINISH = 2'b11;
    
    reg [1:0] state;
    
    // AES core interface signals
    reg aes_start;
    wire aes_done;
    reg [127:0] aes_key;
    reg [127:0] aes_data;
    wire [127:0] aes_out;
    
    // Internal registers
    reg [127:0] keystream;
    reg [127:0] plaintext_reg;
    
    // Instantiate AES core
    aes_core aes_inst (
        .clk(clk),
        .start(aes_start),
        .key(aes_key),
        .data(aes_data),
        .out(aes_out),
        .done(aes_done)
    );
    
    // State machine
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done <= 1'b0;
            aes_start <= 1'b0;
            ciphertext <= 128'b0;
            keystream <= 128'b0;
            plaintext_reg <= 128'b0;
            aes_key <= 128'b0;
            aes_data <= 128'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    aes_start <= 1'b0;
                    if (start) begin
                        // Store plaintext
                        plaintext_reg <= plaintext;
                        
                        // Prepare to encrypt counter block
                        // Key = SESSION_KEY
                        // Data = {COUNTER, 96'b0}
                        aes_key <= session_key;
                        aes_data <= {counter, 96'b0};
                        aes_start <= 1'b1;
                        state <= ENCRYPT_COUNTER;
                    end
                end
                
                ENCRYPT_COUNTER: begin
                    aes_start <= 1'b0;  // De-assert start
                    if (aes_done) begin
                        keystream <= aes_out;
                        state <= XOR_DATA;
                    end
                end
                
                XOR_DATA: begin
                    // CTR mode: Ciphertext = Plaintext XOR Keystream
                    ciphertext <= plaintext_reg ^ keystream;
                    state <= FINISH;
                end
                
                FINISH: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
