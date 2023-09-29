#!/bin/python3
# Basic script to dump binary file to WOZMON
import argparse
from time import sleep

# Wrapper function to parse int arguments with literal prefixes
def int_literal(str):
  return int(str, base=0)

# Unify CR handling
def cr_flush():
  print("", end=args.newline)

# Parse arguments
argument_parser = argparse.ArgumentParser()
argument_parser.add_argument("bin", type=argparse.FileType("rb"), help="Path to binary file to be loaded to WOZMON.")
argument_parser.add_argument("-n", "--newline", action='store_const', const = '\r\n', default='\r', help="Include newline character in line endings for compatibility with modern terminal formatting (defaults to only CR for WOZMON).")
argument_parser.add_argument("-o", "--origin", type=int_literal, default=0, help="Memory-address origin to load binary at.")
argument_parser.add_argument("-t", "--throttle", action='store_true', help="Throttle output to avoid overflowing WOZMON device's input buffer.")
args = argument_parser.parse_args()

# Prepare variables for writing
first_byte     = True
bin_byte_array = args.bin.read()
byte_address   = args.origin
# Write data with WOZMON formatting
for bin_byte in bin_byte_array:
  # Check if this is the first byte or 16-byte multiple
  if first_byte or ((byte_address % 16) == 0):
    # Send CR return to flush any pending input
    cr_flush()
    # Output new write address
    print(format(byte_address, "04X")+":", end='')
    # Clear "first byte" flag
    first_byte = False
  # Output next byte
  print(" " + format(bin_byte, "02X"), end='', flush=True)
  # Increment write address
  byte_address = byte_address+1
  if args.throttle:
    sleep(0.005)

# Send CR return to flush any pending input
cr_flush()