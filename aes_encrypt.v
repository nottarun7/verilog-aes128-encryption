// AES Encryption Module
module aes_encrypt(
    input wire clk,
    input wire reset,
    input wire [127:0] plaintext,
    input wire [127:0] key,
    input wire start,
    output wire [127:0] ciphertext,
    output wire done
);

    aes_simple aes_inst(
        .clk(clk),
        .reset(reset),
        .data_in(plaintext),
        .key(key),
        .encrypt(1'b1),
        .start(start),
        .data_out(ciphertext),
        .done(done)
    );

endmodule
