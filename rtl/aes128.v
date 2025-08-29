// Top-level AES-128 encryption (10 rounds). Sequential, 1 round/cycle.
//
// Interface:
//  - Pulse start=1 for one clk when inputs valid
//  - busy=1 while running; done pulses 1 clk when ciphertext valid
module aes128 (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [127:0] key,
    input  wire [127:0] block_in,
    output reg  [127:0] block_out,
    output reg          busy,
    output reg          done
);
    // Round keys bus and convenient slice macro
    wire [1407:0] rks_bus;
    aes_key_expand_fixed KEYEXP(.key(key), .round_keys(rks_bus));
    function [127:0] rk(input integer idx);
        rk = rks_bus[1407-idx*128 -: 128];
    endfunction

    // State/FSM
    localparam IDLE=2'd0, ROUND=2'd1, LAST=2'd2, FIN=2'd3;
    reg [1:0]  st;
    reg [3:0]  r;           // 1..10
    reg [127:0] s;          // current state

    wire [127:0] mid_next;
    wire [127:0] last_next;
    wire [127:0] rk10 = rks_bus[127:0];  // Explicit RK10

    aes_round #(.LAST(0)) RND  (.state_in(s), .round_key(rk(r)),   .state_out(mid_next));
    aes_round #(.LAST(1)) FINAL(.state_in(s), .round_key(rk10),  .state_out(last_next));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st<=IDLE; r<=0; s<=0; block_out<=0; busy<=0; done<=0;
        end else begin
            done<=0;
            case (st)
                IDLE: begin
                    busy<=0;
                    if (start) begin
                        s <= block_in ^ rk(0); // initial AddRoundKey
                        r <= 1;
                        busy<=1;
                        st <= ROUND;
                    end
                end
                ROUND: begin
                    s <= mid_next;      // rounds 1..9
                    r <= r + 1;
                    if (r==9) st<=LAST;
                end
                LAST: begin
                    s <= last_next;     // round 10 (no MixColumns)
                    st <= FIN;
                end
                FIN: begin
                    block_out <= s;     // Output the final state
                    busy<=0; 
                    done<=1;
                    st<=IDLE;
                end
            endcase
        end
    end
endmodule
