#!/usr/bin/env python3
"""
UART Output Parser for Cheshire RISC-V Controller Firmware

This script dynamically reads output from the controller via USB-UART converter,
saves all raw outputs to a log file, parses messages marked with [RISCV], prints them
slower (1.5 seconds delay per message) without the [RISCV] tag, and computes summary 
statistics (best and average accuracy) for training and validation accuracy lists.
The script terminates when "[RISCV] END" is encountered.
"""

import sys
import os
import time
import re
import argparse

try:
    import serial
except ImportError:
    serial = None

def parse_args():
    parser = argparse.ArgumentParser(
        description="Dynamic UART reader and parser for Cheshire RISC-V firmware."
    )
    parser.add_argument(
        "ttyusb",
        nargs="?",
        default=None,
        help="TTY USB port path or device name (e.g., /dev/ttyUSB0 or ttyUSB0)"
    )
    parser.add_argument(
        "baudrate",
        nargs="?",
        type=int,
        default=None,
        help="Baud rate (e.g., 115200)"
    )
    parser.add_argument(
        "-p", "--port",
        type=str,
        default=None,
        help="Serial port path (alternative to positional argument)"
    )
    parser.add_argument(
        "-b", "--baud",
        type=int,
        default=None,
        help="Serial baud rate (alternative to positional argument)"
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default="uart_log.txt",
        help="File path to save all raw UART outputs (default: uart_log.txt)"
    )
    parser.add_argument(
        "-d", "--delay",
        type=float,
        default=1.5,
        help="Delay in seconds between printed messages (default: 1.5)"
    )
    parser.add_argument(
        "--mock-file",
        type=str,
        default=None,
        help="Path to a text file to read mock UART data from instead of serial port (for testing)"
    )
    return parser.parse_args()

def extract_accuracy_stats(numbers_str):
    """
    Parses a string of space-separated or comma-separated numbers and returns (best, average).
    """
    tokens = re.findall(r"[-+]?\d*\.?\d+", numbers_str)
    values = [float(t) for t in tokens if t]
    if not values:
        return None, None
    best_acc = max(values)
    avg_acc = sum(values) / len(values)
    return best_acc, avg_acc

def format_acc_value(val):
    """Formats float value nicely (e.g., integer if whole number, or rounded float)."""
    if val.is_integer():
        return f"{int(val)}"
    return f"{val:.2f}"

def process_line(line_str, log_file, delay):
    """
    Processes a single line of output from UART/mock source.
    Returns True if termination signal ([RISCV] END) was received, False otherwise.
    """
    # Always log raw output to file
    log_file.write(line_str + "\n")
    log_file.flush()

    # Check for [RISCV] tag
    if "[RISCV]" not in line_str:
        return False

    # Check for termination signal: [RISCV] END
    if re.search(r'\[RISCV\]\s*END\b', line_str, re.IGNORECASE):
        cleaned_msg = re.sub(r'\[RISCV\]\s*', '', line_str).strip()
        print(cleaned_msg, flush=True)
        time.sleep(delay)
        return True

    # Check for accuracy output lists (TRAINACC / VALACC)
    acc_match = re.search(
        r'\[RISCV\]\s*(TRAINACC|VALACC|TRAIN|VAL)\s*(?:IN\s+\d+\s+EPOCHS)?:?\s*(.*)',
        line_str,
        re.IGNORECASE
    )

    if acc_match:
        tag_type = acc_match.group(1).upper()
        numbers_str = acc_match.group(2)
        best_acc, avg_acc = extract_accuracy_stats(numbers_str)

        if best_acc is not None and avg_acc is not None:
            label = "Training" if "TRAIN" in tag_type else "Validation"
            print(
                f"{label} Accuracy -> Best: {format_acc_value(best_acc)}, Average: {avg_acc:.2f}",
                flush=True
            )
            time.sleep(delay)
            return False

    # For standard [RISCV] messages (excluding raw accuracy lists):
    cleaned_msg = re.sub(r'\[RISCV\]\s*', '', line_str).strip()
    if cleaned_msg:
        print(cleaned_msg, flush=True)
        time.sleep(delay)

    return False

def main():
    args = parse_args()

    # Resolve port and baudrate
    port_arg = args.port or args.ttyusb
    baud_arg = args.baud or args.baudrate

    if not args.mock_file and (not port_arg or not baud_arg):
        print("Error: Port (ttyusb) and baudrate must be specified (or --mock-file provided for testing).", file=sys.stderr)
        print("Example: python parse_uart.py /dev/ttyUSB0 115200", file=sys.stderr)
        sys.exit(1)

    # Normalize device path (e.g. ttyUSB0 -> /dev/ttyUSB0)
    if port_arg and not port_arg.startswith("/") and not os.path.exists(port_arg):
        dev_path = os.path.join("/dev", port_arg)
        if os.path.exists(dev_path) or port_arg.lower().startswith("tty"):
            port_arg = dev_path

    output_file = args.output
    delay = args.delay

    print(f"Saving output log to: {output_file}")
    if args.mock_file:
        print(f"Reading mock UART data from file: {args.mock_file}")
    else:
        print(f"Opening UART connection on port {port_arg} at baud rate {baud_arg}...")

    with open(output_file, "a", encoding="utf-8") as log_file:
        if args.mock_file:
            # Read from mock file for testing
            with open(args.mock_file, "r", encoding="utf-8") as f:
                for line in f:
                    line_str = line.rstrip("\r\n")
                    is_end = process_line(line_str, log_file, delay)
                    if is_end:
                        print("Reached [RISCV] END. Terminating script.")
                        break
        else:
            if serial is None:
                print("Error: 'pyserial' package is not installed in the current environment.", file=sys.stderr)
                sys.exit(1)

            try:
                ser = serial.Serial(port_arg, baud_arg, timeout=1.0)
            except Exception as e:
                print(f"Error opening serial port {port_arg}: {e}", file=sys.stderr)
                sys.exit(1)

            try:
                while True:
                    line_bytes = ser.readline()
                    if not line_bytes:
                        continue
                    line_str = line_bytes.decode('utf-8', errors='replace').rstrip('\r\n')
                    is_end = process_line(line_str, log_file, delay)
                    if is_end:
                        print("Reached [RISCV] END. Terminating script.")
                        break
            except KeyboardInterrupt:
                print("\nInterrupted by user. Exiting.")
            finally:
                ser.close()

if __name__ == "__main__":
    main()
