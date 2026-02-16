//==============================================================================
// Testbench: tb_secure_telemetry
// Description: Comprehensive testbench for secure telemetry system
//              Tests complete TX -> RX flow with example sensor data
//
// Author: FPGA Secure Telemetry System
// Target: Xilinx Vivado simulation
//==============================================================================

`timescale 1ns / 1ps

module tb_secure_telemetry;

    // Clock and reset
    reg clk;
    reg reset;
    
    // Test parameters
    localparam CLK_PERIOD = 10;  // 100 MHz clock
    
    // Test vectors
    localparam [127:0] ROOT_KEY = 128'hDEADBEEF_CAFEBABE_12345678_9ABCDEF0;
    localparam [31:0] SESSION_ID = 32'h00000001;
    localparam [31:0] COUNTER = 32'h00000000;
    
    // Sensor data (big-endian)
    localparam [15:0] PRESSURE = 16'h7530;   // 30000
    localparam [15:0] FLOW = 16'h1388;       // 5000
    localparam [15:0] VIBRATION = 16'h0834;  // 2100
    
    // Transmitter signals
    reg tx_start;
    reg [47:0] compressed_data;
    wire [191:0] tx_packet;
    wire tx_done;
    
    // Receiver signals
    reg rx_start;
    reg [191:0] rx_packet;
    wire [47:0] recovered_data;
    wire rx_done;
    
    // Instantiate transmitter
    top_secure_tx tx_inst (
        .clk(clk),
        .reset(reset),
        .start(tx_start),
        .root_key(ROOT_KEY),
        .session_id(SESSION_ID),
        .counter(COUNTER),
        .compressed_data(compressed_data),
        .tx_packet(tx_packet),
        .done(tx_done)
    );
    
    // Instantiate receiver
    top_secure_rx rx_inst (
        .clk(clk),
        .reset(reset),
        .start(rx_start),
        .root_key(ROOT_KEY),
        .rx_packet(rx_packet),
        .recovered_data(recovered_data),
        .done(rx_done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        tx_start = 0;
        rx_start = 0;
        compressed_data = 0;
        rx_packet = 0;
        
        // Display test information
        $display("==========================================================");
        $display("FPGA Secure Telemetry System Testbench");
        $display("==========================================================");
        $display("Test Configuration:");
        $display("  ROOT_KEY    = 0x%032X", ROOT_KEY);
        $display("  SESSION_ID  = 0x%08X", SESSION_ID);
        $display("  COUNTER     = 0x%08X", COUNTER);
        $display("");
        $display("Input Sensor Data:");
        $display("  Pressure    = %d (0x%04X)", PRESSURE, PRESSURE);
        $display("  Flow        = %d (0x%04X)", FLOW, FLOW);
        $display("  Vibration   = %d (0x%04X)", VIBRATION, VIBRATION);
        $display("==========================================================");
        $display("");
        
        // Release reset
        #(CLK_PERIOD * 5);
        reset = 0;
        #(CLK_PERIOD * 2);
        
        // Prepare compressed data (big-endian: Pressure, Flow, Vibration)
        compressed_data = {PRESSURE, FLOW, VIBRATION};
        
        // Start transmission
        $display("[%0t ns] Starting transmission...", $time);
        tx_start = 1;
        #CLK_PERIOD;
        tx_start = 0;
        
        // Wait for transmission to complete
        wait(tx_done);
        $display("[%0t ns] Transmission complete!", $time);
        $display("");
        $display("Transmitted Packet (24 bytes = 192 bits):");
        $display("  SESSION_ID  = 0x%08X", tx_packet[191:160]);
        $display("  COUNTER     = 0x%08X", tx_packet[159:128]);
        $display("  CIPHERTEXT  = 0x%032X", tx_packet[127:0]);
        $display("==========================================================");
        $display("");
        
        // Transfer packet to receiver
        #(CLK_PERIOD * 5);
        rx_packet = tx_packet;
        
        // Start reception
        $display("[%0t ns] Starting reception and decryption...", $time);
        rx_start = 1;
        #CLK_PERIOD;
        rx_start = 0;
        
        // Wait for reception to complete
        wait(rx_done);
        $display("[%0t ns] Reception complete!", $time);
        $display("");
        $display("Recovered Sensor Data:");
        $display("  Pressure    = %d (0x%04X)", recovered_data[47:32], recovered_data[47:32]);
        $display("  Flow        = %d (0x%04X)", recovered_data[31:16], recovered_data[31:16]);
        $display("  Vibration   = %d (0x%04X)", recovered_data[15:0], recovered_data[15:0]);
        $display("==========================================================");
        $display("");
        
        // Verify results
        if (recovered_data == compressed_data) begin
            $display("✓ SUCCESS: Decrypted data matches original!");
            $display("  Original:  0x%012X", compressed_data);
            $display("  Recovered: 0x%012X", recovered_data);
        end else begin
            $display("✗ FAILURE: Decrypted data does NOT match!");
            $display("  Expected:  0x%012X", compressed_data);
            $display("  Got:       0x%012X", recovered_data);
        end
        
        $display("==========================================================");
        $display("Simulation Complete");
        $display("==========================================================");
        
        // End simulation
        #(CLK_PERIOD * 10);
        $finish;
    end
    
    // Waveform dump for GTKWave viewing (Icarus Verilog)
    initial begin
        $dumpfile("secure_telemetry.vcd");
        $dumpvars(0, tb_secure_telemetry);
    end

endmodule
