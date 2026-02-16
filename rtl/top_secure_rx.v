//==============================================================================
// Module: top_secure_rx
// Description: Top-level receiver module
//              Extracts packet fields, derives key, and decrypts data
//
// Author: FPGA Secure Telemetry System
// Target: Xilinx Vivado (7-series FPGAs)
//==============================================================================

module top_secure_rx (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [127:0] root_key,
    input wire [191:0] rx_packet,       // 24 bytes received packet
    output reg [47:0] recovered_data,   // 6 bytes: Pressure, Flow, Vibration
    output reg done
);

    // State machine states
    localparam IDLE = 3'b000;
    localparam EXTRACT = 3'b001;
    localparam DERIVE_KEY = 3'b010;
    localparam WAIT_KEY = 3'b011;
    localparam DECRYPT = 3'b100;
    localparam WAIT_DECRYPT = 3'b101;
    localparam EXTRACT_DATA = 3'b110;
    localparam FINISH = 3'b111;
    
    reg [2:0] state;
    
    // Extracted packet fields
    reg [31:0] session_id;
    reg [31:0] counter;
    reg [127:0] ciphertext;
    
    // Internal signals
    reg [127:0] session_key;
    reg [127:0] plaintext;
    
    // Key derivation signals
    reg key_deriv_start;
    wire key_deriv_done;
    wire [127:0] derived_key;
    
    // Decryption signals
    reg decrypt_start;
    wire decrypt_done;
    wire [127:0] decrypted_data;
    
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
    
    // Instantiate decryption module
    aes_ctr_decrypt decrypt_inst (
        .clk(clk),
        .reset(reset),
        .start(decrypt_start),
        .session_key(session_key),
        .counter(counter),
        .ciphertext(ciphertext),
        .plaintext(decrypted_data),
        .done(decrypt_done)
    );
    
    // Main state machine
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done <= 1'b0;
            key_deriv_start <= 1'b0;
            decrypt_start <= 1'b0;
            session_id <= 32'b0;
            counter <= 32'b0;
            ciphertext <= 128'b0;
            session_key <= 128'b0;
            plaintext <= 128'b0;
            recovered_data <= 48'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    key_deriv_start <= 1'b0;
                    decrypt_start <= 1'b0;
                    
                    if (start) begin
                        state <= EXTRACT;
                    end
                end
                
                EXTRACT: begin
                    // Extract fields from packet
                    // Bits [191:160] = SESSION_ID
                    // Bits [159:128] = COUNTER
                    // Bits [127:0]   = CIPHERTEXT
                    session_id <= rx_packet[191:160];
                    counter <= rx_packet[159:128];
                    ciphertext <= rx_packet[127:0];
                    state <= DERIVE_KEY;
                end
                
                DERIVE_KEY: begin
                    key_deriv_start <= 1'b1;
                    state <= WAIT_KEY;
                end
                
                WAIT_KEY: begin
                    key_deriv_start <= 1'b0;
                    if (key_deriv_done) begin
                        session_key <= derived_key;
                        state <= DECRYPT;
                    end
                end
                
                DECRYPT: begin
                    decrypt_start <= 1'b1;
                    state <= WAIT_DECRYPT;
                end
                
                WAIT_DECRYPT: begin
                    decrypt_start <= 1'b0;
                    if (decrypt_done) begin
                        plaintext <= decrypted_data;
                        state <= EXTRACT_DATA;
                    end
                end
                
                EXTRACT_DATA: begin
                    // Extract first 48 bits (6 bytes) from plaintext
                    // The remaining 80 bits are padding zeros
                    recovered_data <= plaintext[127:80];
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
