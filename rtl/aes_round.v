// One AES round (LAST=1 skips MixColumns for final round)
module aes_round #(parameter LAST=0)(
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);
    // Function definitions for AES GF(2^8) operations
    function [7:0] xtime(input [7:0] x);
        xtime = {x[6:0],1'b0} ^ (8'h1b & {8{x[7]}});
    endfunction
    
    function [7:0] mul2(input [7:0] x);
        mul2 = xtime(x);
    endfunction
    
    function [7:0] mul3(input [7:0] x);
        mul3 = xtime(x) ^ x;
    endfunction

    // SubBytes - instantiate S-box modules
    wire [127:0] sb;
    aes_sbox sb00(.in(state_in[  7:  0]), .out(sb[  7:  0]));
    aes_sbox sb01(.in(state_in[ 15:  8]), .out(sb[ 15:  8]));
    aes_sbox sb02(.in(state_in[ 23: 16]), .out(sb[ 23: 16]));
    aes_sbox sb03(.in(state_in[ 31: 24]), .out(sb[ 31: 24]));
    aes_sbox sb04(.in(state_in[ 39: 32]), .out(sb[ 39: 32]));
    aes_sbox sb05(.in(state_in[ 47: 40]), .out(sb[ 47: 40]));
    aes_sbox sb06(.in(state_in[ 55: 48]), .out(sb[ 55: 48]));
    aes_sbox sb07(.in(state_in[ 63: 56]), .out(sb[ 63: 56]));
    aes_sbox sb08(.in(state_in[ 71: 64]), .out(sb[ 71: 64]));
    aes_sbox sb09(.in(state_in[ 79: 72]), .out(sb[ 79: 72]));
    aes_sbox sb10(.in(state_in[ 87: 80]), .out(sb[ 87: 80]));
    aes_sbox sb11(.in(state_in[ 95: 88]), .out(sb[ 95: 88]));
    aes_sbox sb12(.in(state_in[103: 96]), .out(sb[103: 96]));
    aes_sbox sb13(.in(state_in[111:104]), .out(sb[111:104]));
    aes_sbox sb14(.in(state_in[119:112]), .out(sb[119:112]));
    aes_sbox sb15(.in(state_in[127:120]), .out(sb[127:120]));

    // ShiftRows (column-major AES state)
    wire [127:0] sr = {
        sb[127:120], sb[87:80],  sb[47:40],  sb[7:0],
        sb[95:88],   sb[55:48],  sb[15:8],   sb[103:96],
        sb[63:56],   sb[23:16],  sb[111:104],sb[71:64],
        sb[31:24],   sb[119:112],sb[79:72],  sb[39:32]
    };

    // MixColumns (skip on LAST)
    wire [127:0] mc;
    generate 
        if (LAST) begin
            assign mc = sr;
        end else begin
            // Column 0
            wire [7:0] s0_0 = sr[24 +: 8];
            wire [7:0] s1_0 = sr[16 +: 8];
            wire [7:0] s2_0 = sr[8  +: 8];
            wire [7:0] s3_0 = sr[0  +: 8];
            assign mc[24 +: 8] = mul2(s0_0) ^ mul3(s1_0) ^ s2_0        ^ s3_0;
            assign mc[16 +: 8] = s0_0        ^ mul2(s1_0) ^ mul3(s2_0) ^ s3_0;
            assign mc[8  +: 8] = s0_0        ^ s1_0        ^ mul2(s2_0) ^ mul3(s3_0);
            assign mc[0  +: 8] = mul3(s0_0) ^ s1_0        ^ s2_0        ^ mul2(s3_0);
            
            // Column 1
            wire [7:0] s0_1 = sr[56 +: 8];
            wire [7:0] s1_1 = sr[48 +: 8];
            wire [7:0] s2_1 = sr[40 +: 8];
            wire [7:0] s3_1 = sr[32 +: 8];
            assign mc[56 +: 8] = mul2(s0_1) ^ mul3(s1_1) ^ s2_1        ^ s3_1;
            assign mc[48 +: 8] = s0_1        ^ mul2(s1_1) ^ mul3(s2_1) ^ s3_1;
            assign mc[40 +: 8] = s0_1        ^ s1_1        ^ mul2(s2_1) ^ mul3(s3_1);
            assign mc[32 +: 8] = mul3(s0_1) ^ s1_1        ^ s2_1        ^ mul2(s3_1);
            
            // Column 2
            wire [7:0] s0_2 = sr[88 +: 8];
            wire [7:0] s1_2 = sr[80 +: 8];
            wire [7:0] s2_2 = sr[72 +: 8];
            wire [7:0] s3_2 = sr[64 +: 8];
            assign mc[88 +: 8] = mul2(s0_2) ^ mul3(s1_2) ^ s2_2        ^ s3_2;
            assign mc[80 +: 8] = s0_2        ^ mul2(s1_2) ^ mul3(s2_2) ^ s3_2;
            assign mc[72 +: 8] = s0_2        ^ s1_2        ^ mul2(s2_2) ^ mul3(s3_2);
            assign mc[64 +: 8] = mul3(s0_2) ^ s1_2        ^ s2_2        ^ mul2(s3_2);
            
            // Column 3
            wire [7:0] s0_3 = sr[120 +: 8];
            wire [7:0] s1_3 = sr[112 +: 8];
            wire [7:0] s2_3 = sr[104 +: 8];
            wire [7:0] s3_3 = sr[96 +: 8];
            assign mc[120 +: 8] = mul2(s0_3) ^ mul3(s1_3) ^ s2_3        ^ s3_3;
            assign mc[112 +: 8] = s0_3        ^ mul2(s1_3) ^ mul3(s2_3) ^ s3_3;
            assign mc[104 +: 8] = s0_3        ^ s1_3        ^ mul2(s2_3) ^ mul3(s3_3);
            assign mc[96  +: 8] = mul3(s0_3) ^ s1_3        ^ s2_3        ^ mul2(s3_3);
        end
    endgenerate

    // AddRoundKey
    assign state_out = mc ^ round_key;
endmodule
