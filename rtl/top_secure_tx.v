//==============================================================================
// Module: top_secure_tx
// Description: Top-level transmitter module
//              Orchestrates key derivation, encryption, and packet formatting
//
// Author: FPGA Secure Telemetry System
// Target: Xilinx Vivado (7-series FPGAs)
//==============================================================================

module top_secure_tx (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [127:0] root_key,
    input wire [31:0] session_id,
    input wire [31:0] counter,
    input wire [47:0] compressed_data,  // 6 bytes: Pressure, Flow, Vibration
    output wire [191:0] tx_packet,      // 24 bytes output packet
    output reg done
);

    // State machine states
    localparam IDLE = 3'b000;
    localparam DERIVE_KEY = 3'b001;
    localparam WAIT_KEY = 3'b010;
    localparam ENCRYPT = 3'b011;
    localparam WAIT_ENCRYPT = 3'b100;
    localparam FORMAT = 3'b101;
    localparam WAIT_FORMAT = 3'b110;
    localparam FINISH = 3'b111;
    
    reg [2:0] state;
    
    // Internal signals
    reg [127:0] session_key;
    reg [127:0] plaintext;
    reg [127:0] ciphertext;
    
    // Key derivation signals
    reg key_deriv_start;
    wire key_deriv_done;
    wire [127:0] derived_key;
    
    // Encryption signals
    reg encrypt_start;
    wire encrypt_done;
    wire [127:0] encrypted_data;
    
    // Packet formatter signals
    reg format_start;
    wire format_done;
    wire [191:0] formatted_packet;
    
    // Instantiate key derivation module
    key_derivation key_deriv_inst (
        .clk(clk),
        .reset(reset),
        .start(key_deriv_start),
        .root_key(root_key),
        .session_id(session_id),
        .session_key(derived_key),
        .done(key_deriv_done)
    );
    
    // Instantiate encryption module
    aes_ctr_encrypt encrypt_inst (
        .clk(clk),
        .reset(reset),
        .start(encrypt_start),
        .session_key(session_key),
        .counter(counter),
        .plaintext(plaintext),
        .ciphertext(encrypted_data),
        .done(encrypt_done)
    );
    
    // Instantiate packet formatter
    packet_formatter formatter_inst (
        .clk(clk),
        .reset(reset),
        .start(format_start),
        .session_id(session_id),
        .counter(counter),
        .ciphertext(ciphertext),
        .packet(formatted_packet),
        .done(format_done)
    );
    
    // Assign output
    assign tx_packet = formatted_packet;
    
    // Main state machine
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done <= 1'b0;
            key_deriv_start <= 1'b0;
            encrypt_start <= 1'b0;
            format_start <= 1'b0;
            session_key <= 128'b0;
            plaintext <= 128'b0;
            ciphertext <= 128'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    key_deriv_start <= 1'b0;
                    encrypt_start <= 1'b0;
                    format_start <= 1'b0;
                    
                    if (start) begin
                        // Prepare plaintext: pad compressed_data to 128 bits
                        // compressed_data is 48 bits (6 bytes)
                        // Pad with 80 bits (10 bytes) of zeros
                        plaintext <= {compressed_data, 80'b0};
                        state <= DERIVE_KEY;
                    end
                end
                
                DERIVE_KEY: begin
                    key_deriv_start <= 1'b1;
                    state <= WAIT_KEY;
                end
                
                WAIT_KEY: begin
                    key_deriv_start <= 1'b0;
                    if (key_deriv_done) begin
                        session_key <= derived_key;
                        state <= ENCRYPT;
                    end
                end
                
                ENCRYPT: begin
                    encrypt_start <= 1'b1;
                    state <= WAIT_ENCRYPT;
                end
                
                WAIT_ENCRYPT: begin
                    encrypt_start <= 1'b0;
                    if (encrypt_done) begin
                        ciphertext <= encrypted_data;
                        state <= FORMAT;
                    end
                end
                
                FORMAT: begin
                    format_start <= 1'b1;
                    state <= WAIT_FORMAT;
                end
                
                WAIT_FORMAT: begin
                    format_start <= 1'b0;
                    if (format_done) begin
                        state <= FINISH;
                    end
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
