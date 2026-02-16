# FPGA Secure Telemetry - Quick Demo

## Setup

1. **Install Icarus Verilog**
   - Already installed at: `C:\iverilog\bin`
   - Add to PATH if needed

2. **Install GTKWave** (for waveforms)
   - Already installed

---

## Run Simulation Manually

### Step 1: Compile

```powershell
cd c:\final-year\tb
C:\iverilog\bin\iverilog.exe -o sim.vvp -I ../rtl ../rtl/*.v tb_secure_telemetry.v
```

### Step 2: Run Simulation

```powershell
C:\iverilog\bin\vvp.exe sim.vvp
```

**Output shows:**
- Input sensor data (Pressure, Flow, Vibration)
- Encrypted packet (SESSION_ID, COUNTER, CIPHERTEXT)
- Decrypted data
- ✓ SUCCESS if encryption/decryption works

### Step 3: View Waveforms

```powershell
gtkwave secure_telemetry.vcd
```

**Key signals to view:**
- `compressed_data` - Input (48 bits)
- `tx_packet` - Encrypted output (192 bits)
- `recovered_data` - Decrypted output (48 bits)
- `tx_done`, `rx_done` - Completion signals

---

## Test with Custom Input

### Edit Testbench

Open `tb\tb_secure_telemetry.v` and modify lines 20-22:

```verilog
localparam [15:0] PRESSURE = 16'hXXXX;   // Your value
localparam [15:0] FLOW = 16'hXXXX;       // Your value
localparam [15:0] VIBRATION = 16'hXXXX;  // Your value
```

Example:
```verilog
localparam [15:0] PRESSURE = 16'h7530;   // 30000
localparam [15:0] FLOW = 16'h1388;       // 5000
localparam [15:0] VIBRATION = 16'h0834;  // 2100
```

Then recompile and run (Steps 1-2).

---

## Expected Results

**Console Output:**
```
Input Sensor Data:
  Pressure    = 30000 (0x7530)
  Flow        = 5000 (0x1388)
  Vibration   = 2100 (0x0834)

Transmitted Packet:
  SESSION_ID  = 0x00000001
  COUNTER     = 0x00000000
  CIPHERTEXT  = 0xab9dad66c2cababe123456789abcdef0

Recovered Sensor Data:
  Pressure    = 30000 (0x7530)
  Flow        = 5000 (0x1388)
  Vibration   = 2100 (0x0834)

✓ SUCCESS: Decrypted data matches original!
```

**Waveform File:** `secure_telemetry.vcd` (view in GTKWave)

---

## File Structure

```
c:\final-year\
├── rtl\              # Verilog RTL modules (7 files)
│   ├── aes_core.v
│   ├── key_derivation.v
│   ├── aes_ctr_encrypt.v
│   ├── aes_ctr_decrypt.v
│   ├── packet_formatter.v
│   ├── top_secure_tx.v
│   └── top_secure_rx.v
└── tb\               # Testbench
    └── tb_secure_telemetry.v
```

---

## GTKWave - How to View Signals

### Finding Signals

In GTKWave's **SST** window (left side):

All the main signals are directly under `tb_secure_telemetry` - **you don't need to expand anything!**

Look for these signals (they should be visible immediately):
- `compressed_data[47:0]` or `compressed_data` - Your input
- `tx_packet[191:0]` or `tx_packet` - Encrypted output  
- `recovered_data[47:0]` or `recovered_data` - Decrypted output
- `tx_done` - TX finished flag
- `rx_done` - RX finished flag
- `clk` - Clock signal

**Note:** If signal names don't show, look for the bit widths:
- 48-bit signals = `compressed_data` and `recovered_data`
- 192-bit signal = `tx_packet`
- 1-bit signals = control signals

### Key Signals to Add

**From `tb_secure_telemetry` (top level):**
- `clk` - Clock signal
- `compressed_data[47:0]` - **Input sensor data (6 bytes)**
- `tx_packet[191:0]` - **Encrypted output (24 bytes)**
- `recovered_data[47:0]` - **Decrypted output (6 bytes)**
- `tx_done` - Transmitter finished
- `rx_done` - Receiver finished

**From `tx_inst` (transmitter internals):**
- `state[2:0]` - TX state machine
- `plaintext[127:0]` - Padded input before encryption
- `ciphertext[127:0]` - Encrypted data (16 bytes)
- `session_key[127:0]` - Derived encryption key

**From `rx_inst` (receiver internals):**
- `state[2:0]` - RX state machine
- `session_id[31:0]` - Extracted from packet
- `counter[31:0]` - Extracted from packet

### How to Add Signals

1. Click on a signal in SST window
2. Click **"Append"** button (or drag signal to Signals pane)
3. Signal appears in waveform viewer

### Change Display Format

- Right-click signal → **Data Format** → **Hex** (for data)
- Right-click signal → **Data Format** → **ASCII** (for state names)

### Quick View Setup

Add these signals in order:
1. `clk`
2. `tx_inst.state[2:0]` (set to ASCII)
3. `compressed_data[47:0]` (set to Hex)
4. `tx_packet[191:0]` (set to Hex)
5. `tx_done`
6. `rx_inst.state[2:0]` (set to ASCII)
7. `recovered_data[47:0]` (set to Hex)
8. `rx_done`

### Zoom to See Activity

- Click **Zoom Fit** (or press `Ctrl+Alt+F`)
- Use mouse wheel to zoom in/out
- Click and drag to pan

---

## Verification for Faculty

To prove the encryption is real (not fake):

1. **Open verification tool:**
   ```
   Double-click: c:\final-year\verification.html
   ```

2. **Enter same values** as your Verilog testbench

3. **Compare ciphertext** - Should match simulation output exactly

4. **Faculty can verify independently** using:
   - The provided web tool (uses CryptoJS library)
   - Online AES calculators (CyberChef, etc.)
   - Any AES-128 CTR implementation

See `VERIFICATION.md` for detailed instructions.

