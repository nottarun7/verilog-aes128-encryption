// AES Decryption Module
module aes_decrypt(
    input wire clk,
    input wire reset,
    input wire [127:0] ciphertext,
    input wire [127:0] key,
    input wire start,
    output wire [127:0] plaintext,
    output wire done
);

    aes_simple aes_inst(
        .clk(clk),
        .reset(reset),
        .data_in(ciphertext),
        .key(key),
        .encrypt(1'b0),
        .start(start),
        .data_out(plaintext),
        .done(done)
    );

endmodule
