// Feistel-based cipher for demonstration
// This guarantees that encrypt and decrypt are perfect inverses
module aes_simple(
    input wire clk,
    input wire reset,
    input wire [127:0] data_in,
    input wire [127:0] key,
    input wire encrypt,
    input wire start,
    output reg [127:0] data_out,
    output reg done
);

    reg [63:0] left, right;
    reg [3:0] round;
    reg busy;
    reg [127:0] round_keys [0:9];
    
    // Round function - non-linear mixing
    function [63:0] f_function;
        input [63:0] data;
        input [127:0] rkey;
        reg [63:0] temp;
        begin
            temp = data ^ rkey[63:0];
            // Non-linear transformation using bit rotations and XOR
            f_function = {temp[62:0], temp[63]} ^ {temp[31:0], temp[63:32]} ^ rkey[127:64];
        end
    endfunction
    
    // Generate round keys
    task generate_keys;
        input [127:0] master_key;
        integer i;
        reg [127:0] temp_key;
        begin
            temp_key = master_key;
            for (i = 0; i < 10; i = i + 1) begin
                round_keys[i] = temp_key;
                temp_key = {temp_key[119:0], temp_key[127:120]} ^ {i[7:0], temp_key[127:8]};
            end
        end
    endtask
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            left <= 64'h0;
            right <= 64'h0;
            round <= 4'h0;
            data_out <= 128'h0;
            done <= 1'b0;
            busy <= 1'b0;
        end else begin
            if (start && !busy) begin
                // Split input into left and right halves
                left <= data_in[127:64];
                right <= data_in[63:0];
                round <= 4'h0;
                done <= 1'b0;
                busy <= 1'b1;
                generate_keys(key);
            end else if (busy) begin
                if (round < 4'd10) begin
                    if (encrypt) begin
                        // Feistel encryption: L' = R, R' = L XOR f(R, K)
                        left <= right;
                        right <= left ^ f_function(right, round_keys[round]);
                    end else begin
                        // Feistel decryption: R' = L, L' = R XOR f(L, K)
                        right <= left;
                        left <= right ^ f_function(left, round_keys[9 - round]);
                    end
                    round <= round + 1;
                end else begin
                    // Combine halves
                    data_out <= {left, right};
                    done <= 1'b1;
                    busy <= 1'b0;
                end
            end
        end
    end

endmodule
