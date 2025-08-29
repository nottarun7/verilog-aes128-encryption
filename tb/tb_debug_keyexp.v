`timescale 1ns/1ps
module tb_debug_keyexp;
    reg [127:0] key;
    wire [1407:0] round_keys;
    
    aes_key_expand_fixed dut(.key(key), .round_keys(round_keys));
    
    function [127:0] get_rk(input integer idx);
        get_rk = round_keys[1407-idx*128 -: 128];
    endfunction
    
    initial begin
        // NIST test key
        key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        #1;
        
        $display("Key expansion debug for NIST test vector:");
        $display("Key:  %032h", key);
        $display("RK0:  %032h", get_rk(0));
        $display("RK1:  %032h", get_rk(1));
        $display("RK2:  %032h", get_rk(2));
        $display("RK10: %032h", get_rk(10));
        
        // Expected NIST round keys (from standard):
        $display("");
        $display("Expected NIST round keys:");
        $display("RK0:  2b7e151628aed2a6abf7158809cf4f3c");
        $display("RK1:  a0fafe1788542cb123a339392a6c7605");
        $display("RK2:  f2c295f27a96b9435935807a7359f67f");
        
        $finish;
    end
endmodule
