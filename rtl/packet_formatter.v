//==============================================================================
// Module: packet_formatter
// Description: Formats encrypted data into transmission packet
//              Packet structure (24 bytes = 192 bits):
//              [SESSION_ID (32) | COUNTER (32) | CIPHERTEXT (128)]
//
// Author: FPGA Secure Telemetry System
// Target: Xilinx Vivado (7-series FPGAs)
//==============================================================================

module packet_formatter (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [31:0] session_id,
    input wire [31:0] counter,
    input wire [127:0] ciphertext,
    output reg [191:0] packet,  // 24 bytes
    output reg done
);

    // State machine states
    localparam IDLE = 1'b0;
    localparam FORMAT = 1'b1;
    
    reg state;
    
    // State machine
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done <= 1'b0;
            packet <= 192'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        // Concatenate fields in big-endian order
                        // Bits [191:160] = SESSION_ID
                        // Bits [159:128] = COUNTER
                        // Bits [127:0]   = CIPHERTEXT
                        packet <= {session_id, counter, ciphertext};
                        state <= FORMAT;
                    end
                end
                
                FORMAT: begin
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
