#!/usr/bin/env python3
"""
AES-128 Test Tool
Simple Python script to test AES encryption and compare with your Verilog implementation.
"""

from Crypto.Cipher import AES
import binascii

def aes_encrypt_ecb(key_hex, plaintext_hex):
    """
    Encrypt using AES-128 ECB mode
    """
    key = bytes.fromhex(key_hex)
    plaintext = bytes.fromhex(plaintext_hex)
    
    cipher = AES.new(key, AES.MODE_ECB)
    ciphertext = cipher.encrypt(plaintext)
    
    return ciphertext.hex().upper()

def text_to_hex(text):
    """
    Convert ASCII text to hex string
    """
    return text.encode('ascii').hex()

def test_verilog_output():
    """
    Test with the same values as your Verilog testbench
    """
    print("=== AES-128 Python Test Tool ===")
    print("Testing with your Verilog testbench values:")
    print()
    
    # Your current test values
    key_text = "MySecretKey12345"
    plaintext_text = "Final year proj!"
    
    # Convert to hex
    key_hex = text_to_hex(key_text)
    plaintext_hex = text_to_hex(plaintext_text)
    
    print(f"Key (text):       '{key_text}'")
    print(f"Key (hex):        {key_hex.upper()}")
    print(f"Plaintext (text): '{plaintext_text}'")
    print(f"Plaintext (hex):  {plaintext_hex.upper()}")
    print()
    
    # Encrypt
    ciphertext = aes_encrypt_ecb(key_hex, plaintext_hex)
    
    print(f"Python AES Result: {ciphertext}")
    print()
    
    # Test with NIST standard vector that we know works
    print("=== NIST Standard Test Vector ===")
    nist_key = "2b7e151628aed2a6abf7158809cf4f3c"
    nist_plain = "6bc1bee22e409f96e93d7e117393172a"
    nist_expected = "3ad77bb40d7a3660a89ecaf32466ef97"
    
    nist_result = aes_encrypt_ecb(nist_key, nist_plain)
    
    print(f"NIST Key:        {nist_key.upper()}")
    print(f"NIST Plaintext:  {nist_plain.upper()}")
    print(f"Python Result:   {nist_result}")
    print(f"Expected:        {nist_expected.upper()}")
    
    if nist_result.upper() == nist_expected.upper():
        print("✅ NIST test PASSES - Python AES is working correctly")
    else:
        print("❌ NIST test FAILS - Python AES issue")
    print()
    
    # Compare with your Verilog output
    verilog_output = "0FD25AED790D7E36410A16A21DC38409"  # Your last result
    
    print("=== YOUR VERILOG COMPARISON ===")
    print(f"Python:  {ciphertext}")
    print(f"Verilog: {verilog_output}")
    
    if ciphertext == verilog_output:
        print("✅ MATCH! Your Verilog implementation is CORRECT!")
    else:
        print("❌ MISMATCH! Your Verilog has an issue.")
        print("The correct result should be the Python result.")
    
    print()
    return ciphertext

def test_custom_input():
    """
    Test with custom input
    """
    print("=== Custom Test ===")
    key_text = input("Enter 16-character key: ").ljust(16)[:16]
    plaintext_text = input("Enter 16-character plaintext: ").ljust(16)[:16]
    
    key_hex = text_to_hex(key_text)
    plaintext_hex = text_to_hex(plaintext_text)
    
    print(f"\nKey (hex):        {key_hex.upper()}")
    print(f"Plaintext (hex):  {plaintext_hex.upper()}")
    
    ciphertext = aes_encrypt_ecb(key_hex, plaintext_hex)
    print(f"Ciphertext (hex): {ciphertext}")
    
    print("\nTo test in your Verilog:")
    print(f'key = {{"{key_text}"}};')
    print(f'pt  = {{"{plaintext_text}"}};')
    print(f"Expected result: {ciphertext.lower()}")

if __name__ == "__main__":
    try:
        test_verilog_output()
        
        print("=" * 50)
        choice = input("Test with custom input? (y/n): ")
        if choice.lower() == 'y':
            test_custom_input()
            
    except ImportError:
        print("Error: pycryptodome not installed")
        print("Install with: pip install pycryptodome")
    except Exception as e:
        print(f"Error: {e}")
