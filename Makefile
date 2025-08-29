# Simple AES-128 Makefile
# Usage: make test

# Compiler
IVERILOG = iverilog
VVP = vvp

# Directories
RTL_DIR = rtl
TB_DIR = tb
BUILD_DIR = build

# Source files
RTL_SOURCES = $(RTL_DIR)/aes_sbox.v $(RTL_DIR)/aes_round.v $(RTL_DIR)/aes_key_expand_fixed.v $(RTL_DIR)/aes128.v
TESTBENCH = $(TB_DIR)/tb_aes128.v

# Default target
all: test

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile and run AES test
test: $(BUILD_DIR)
	$(IVERILOG) -g2012 -I $(RTL_DIR) -o $(BUILD_DIR)/aes_test.out $(RTL_SOURCES) $(TESTBENCH)
	$(VVP) $(BUILD_DIR)/aes_test.out

# View waveforms (requires gtkwave)
waves: test
	gtkwave $(BUILD_DIR)/aes128.vcd &

# Clean build files
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.vcd

# Show help
help:
	@echo "Available targets:"
	@echo "  test   - Compile and run AES test"
	@echo "  waves  - Run test and open waveform viewer"
	@echo "  clean  - Remove build files"
	@echo "  help   - Show this help"

.PHONY: all test waves clean help
