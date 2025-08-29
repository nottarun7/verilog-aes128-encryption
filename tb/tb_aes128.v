`timescale 1ns/1ps
module tb_aes128;
    reg clk=0; always #5 clk=~clk; // 100 MHz
    reg rst_n=0, start=0;
    reg  [127:0] key, pt;
    wire [127:0] ct;
    wire busy, done;

    aes128 dut(.clk(clk), .rst_n(rst_n), .start(start),
               .key(key), .block_in(pt), .block_out(ct),
               .busy(busy), .done(done));

    // Function to convert ASCII string to 128-bit hex (pads with zeros if needed)
    function [127:0] ascii_to_128bit;
        input [127:0] ascii_str;  // Can hold up to 16 ASCII characters
        begin
            ascii_to_128bit = ascii_str;
        end
    endfunction

    initial begin
        $dumpfile("build/aes128.vcd");
        $dumpvars(0, tb_aes128);

        repeat(4) @(negedge clk); rst_n=1;

        $display("=== AES-128 ENCRYPTION TEST ===");
        $display("Easy Text Input - Automatically Converts to AES Format");
        $display("========================================================");

        // EASY TEXT INPUT - JUST CHANGE THESE STRINGS:
        // Note: Strings must be exactly 16 characters or will be padded/truncated
        
        // Method 1: Direct ASCII assignment (recommended)
        key = {"MySecretKey12345"};  // Exactly 16 characters
        pt  = {"Final year proj!"};  // Exactly 16 characters
        
        // Display original text
        $display("Key (text):       '%s'", key);
        $display("Plaintext (text): '%s'", pt);
        $display("");
        
        // Display hex equivalent  
        $display("Key (hex):        %032h", key);
        $display("Plaintext (hex):  %032h", pt);
        $display("");

        @(negedge clk) start=1; @(negedge clk) start=0;

        wait(done);
        $display("Ciphertext (hex): %032h", ct);
        $display("========================================================");
        $display("");
        $display("FOR WEB TOOL VERIFICATION:");
        $display("Plain Text: Final year proj!");
        $display("Secret Key: MySecretKey12345"); 
        $display("Expected Ciphertext: %032h", ct);
        $display("Settings: ECB mode, NoPadding, 128-bit, Hex output");
        $display("========================================================");
        
        #20 $finish;
    end
endmodule
