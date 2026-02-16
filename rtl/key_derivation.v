//==============================================================================
// Module: key_derivation
// Description: Derives session key from root key and session ID
//              SESSION_KEY = AES(ROOT_KEY, {SESSION_ID, 96'b0})
//
// Author: FPGA Secure Telemetry System
// Target: Xilinx Vivado (7-series FPGAs)
//==============================================================================

module key_derivation (
    input wire clk,
    input wire reset,
    input wire start,
    input wire [127:0] root_key,
    input wire [31:0] session_id,
    output reg [127:0] session_key,
    output reg done
);

    // State machine states
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam FINISH = 2'b10;
    
    reg [1:0] state;
    
    // AES core interface signals
    reg aes_start;
    wire aes_done;
    reg [127:0] aes_key;
    reg [127:0] aes_data;
    wire [127:0] aes_out;
    
    // Instantiate AES core (assumed to exist)
    aes_core aes_inst (
        .clk(clk),
        .start(aes_start),
        .key(aes_key),
        .data(aes_data),
        .out(aes_out),
        .done(aes_done)
    );
    
    // State machine and control logic
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done <= 1'b0;
            aes_start <= 1'b0;
            session_key <= 128'b0;
            aes_key <= 128'b0;
            aes_data <= 128'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    aes_start <= 1'b0;
                    if (start) begin
                        // Prepare AES inputs
                        // Key = ROOT_KEY
                        // Data = {SESSION_ID, 96'b0}
                        aes_key <= root_key;
                        aes_data <= {session_id, 96'b0};
                        aes_start <= 1'b1;
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    aes_start <= 1'b0;  // De-assert start after one cycle
                    if (aes_done) begin
                        session_key <= aes_out;
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
