`timescale 1ns/1ps
module tb_debug_text;
    reg [127:0] key_str, pt_str;
    
    initial begin
        // Test text assignment
        key_str = {"MySecretKey12345"};
        pt_str = {"Final year proj!"};
        
        $display("Debug text assignment:");
        $display("Key string: '%s'", key_str);
        $display("Key hex:    %032h", key_str);
        $display("PT string:  '%s'", pt_str);  
        $display("PT hex:     %032h", pt_str);
        
        // Expected from xxd:
        $display("");
        $display("Expected from xxd:");
        $display("Key should be: 4d795365637265744b65793132333435");
        $display("PT should be:  46696e616c20796561722070726f6a21");
        
        $finish;
    end
endmodule
