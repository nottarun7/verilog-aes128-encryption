`timescale 1ns/1ps

module aes_tb;
    reg clk;
    reg reset;
    reg [127:0] plaintext;
    reg [127:0] key;
    reg start_enc, start_dec;
    wire [127:0] ciphertext;
    wire [127:0] decrypted_text;
    wire enc_done, dec_done;
    
    // File handling
    integer csv_file, out_enc, out_dec;
    integer status;
    reg [1023:0] line;
    integer row_count;
    integer value1, value2;
    integer scan_result;
    reg [7:0] char;
    
    // Instantiate encryption module
    aes_encrypt encrypt_inst(
        .clk(clk),
        .reset(reset),
        .plaintext(plaintext),
        .key(key),
        .start(start_enc),
        .ciphertext(ciphertext),
        .done(enc_done)
    );
    
    // Instantiate decryption module
    aes_decrypt decrypt_inst(
        .clk(clk),
        .reset(reset),
        .ciphertext(ciphertext),
        .key(key),
        .start(start_dec),
        .plaintext(decrypted_text),
        .done(dec_done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test procedure
    initial begin
        // Initialize signals
        reset = 1;
        start_enc = 0;
        start_dec = 0;
        key = 128'h2b7e151628aed2a6abf7158809cf4f3c; // AES-128 test key
        row_count = 0;
        
        // Open files
        csv_file = $fopen("data.csv", "r");
        out_enc = $fopen("encrypted_data.csv", "w");
        out_dec = $fopen("decrypted_data.csv", "w");
        
        if (csv_file == 0) begin
            $display("ERROR: Could not open data.csv");
            $finish;
        end
        
        // Setup VCD dump for GTKWave
        $dumpfile("aes_waveform.vcd");
        $dumpvars(0, aes_tb);
        
        // Reset
        #20 reset = 0;
        #10;
        
        // Write headers to output files
        $fwrite(out_enc, "Dynamic level (encrypted),Reservoir pressure (encrypted)\n");
        $fwrite(out_dec, "Dynamic level (decrypted),Reservoir pressure (decrypted)\n");
        
        // Skip header line
        status = $fgets(line, csv_file);
        
        // Process CSV data
        while (!$feof(csv_file)) begin
            status = $fgets(line, csv_file);
            if (status != 0) begin
                // Parse CSV line - handle quotes
                scan_result = $sscanf(line, "%d,%d", value1, value2);
                
                if (scan_result == 2) begin
                    row_count = row_count + 1;
                    
                    // Pack data into 128-bit plaintext (32 bits for each value, rest zeros)
                    plaintext = {96'h0, value2[31:0], value1[31:0]};
                    
                    $display("Row %0d: Processing Dynamic=%0d, Pressure=%0d", row_count, value1, value2);
                    
                    // Start encryption
                    start_enc = 0;
                    start_dec = 0;
                    #10;
                    
                    @(posedge clk);
                    start_enc = 1;
                    @(posedge clk);
                    start_enc = 0;
                    
                    // Wait for encryption to complete
                    wait(enc_done);
                    @(posedge clk);
                    @(posedge clk);
                    
                    $display("  Encrypted: %h", ciphertext);
                    
                    // Write encrypted data as hex
                    $fwrite(out_enc, "%h,%h\n", 
                            ciphertext[127:64], ciphertext[63:0]);
                    
                    // Start decryption
                    @(posedge clk);
                    start_dec = 1;
                    @(posedge clk);
                    start_dec = 0;
                    
                    // Wait for decryption to complete
                    wait(dec_done);
                    @(posedge clk);
                    @(posedge clk);
                    @(posedge clk);
                    
                    $display("  Decrypted: Dynamic=%0d, Pressure=%0d", 
                            decrypted_text[31:0], decrypted_text[63:32]);
                    
                    // Write decrypted data
                    $fwrite(out_dec, "%0d,%0d\n", 
                            decrypted_text[31:0], decrypted_text[63:32]);
                    
                    // Verify encryption/decryption
                    if (plaintext[31:0] == decrypted_text[31:0] && plaintext[63:32] == decrypted_text[63:32]) begin
                        $display("  PASS: Encryption/Decryption successful");
                    end else begin
                        $display("  FAIL: Mismatch detected! Expected: Dynamic=%0d, Pressure=%0d", value1, value2);
                        $display("                            Got:      Dynamic=%0d, Pressure=%0d", 
                                decrypted_text[31:0], decrypted_text[63:32]);
                    end
                    
                    #50; // Delay between rows
                end
            end
        end
        
        // Close files
        $fclose(csv_file);
        $fclose(out_enc);
        $fclose(out_dec);
        
        $display("\n========================================");
        $display("Total rows processed: %0d", row_count);
        $display("Encrypted data saved to: encrypted_data.csv");
        $display("Decrypted data saved to: decrypted_data.csv");
        $display("Waveform saved to: aes_waveform.vcd");
        $display("========================================\n");
        
        #100;
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #5000000; // 5ms timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
