# AES-128 Encryption Implementation

Simple Verilog implementation of AES-128 encryption algorithm with **easy text input**.

## Quick Start

```bash
# Run AES test
make test

# View waveforms
make waves

# Clean build files
make clean
```

## How to Change Key and Plaintext

### 1. Edit the Test File
```bash
nano tb/tb_aes128.v
```

### 2. Change Lines 32-33 (Easy Text Input)
```verilog
key = {"MySecretKey12345"};  // <-- Change this text (exactly 16 characters)
pt  = {"Final year proj!"};  // <-- Change this text (exactly 16 characters)
```

### 3. Run Test
```bash
make test
```

## Text Input Rules

✅ **Exactly 16 characters** for both key and plaintext  
✅ **Any ASCII text** (letters, numbers, symbols, spaces)  
✅ **Automatic hex conversion** - no manual conversion needed  
❌ **Shorter or longer text** will be padded/truncated  

## Examples

```verilog
// Simple examples:
key = {"1234567890123456"};  // Numbers
pt  = {"Hello World!!!!!"};  // Text with padding

// Your project:
key = {"MySecretKey12345"};  // Your secret key
pt  = {"Final year proj!"};  // Your message

// Custom examples:
key = {"PASSWORD12345678"};  // Custom key
pt  = {"This is a test!!"};  // Custom message
```

## Web Tool Verification

After running `make test`, use these values in any online AES tool:

- **Plain Text:** `Final year proj!` (copy from output)
- **Secret Key:** `MySecretKey12345` (copy from output)
- **Settings:** ECB mode, NoPadding, 128-bit, Hex output
- **Expected Result:** Match the "Ciphertext (hex)" from your test output

## Files

- `rtl/aes128.v` - Main AES module
- `rtl/aes_round.v` - Round logic  
- `rtl/aes_key_expand_fixed.v` - Key expansion
- `rtl/aes_sbox.v` - S-box implementation
- `tb/tb_aes128.v` - Test file (edit lines 32-33)