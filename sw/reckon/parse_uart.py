# Copyright 2026 Michelangelo Barocci, Politecnico di Torino.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Michelangelo Barocci <michelangelo.barocci@polito.it>

#!/usr/bin/env python3
"""
UART Output Parser for Cheshire RISC-V Controller Firmware

This script dynamically reads output from the controller via USB-UART converter,
saves all raw outputs to a log file, parses messages marked with [RISCV], prints them
with randomized delays (+-30% variability around the base delay) without the [RISCV] tag,
and computes summary statistics (best and average accuracy as percentage) for training
and validation accuracy lists. Converts cycle count lines into scientific notation.
Optionally renders a live terminal plot using plotext and opens a Matplotlib GUI plot window upon exit.

Key behavior:
- Excludes [RISCV] tag from standard output messages.
- Ignores printing the NSAMP / NEPOCHS setup line, but saves NSAMP and NEPOCHS to calculate accuracy %.
- Ignores printing raw accuracy count lists, calculating and printing Best & Average Accuracy (%) instead.
- Plots accuracy evolution (Train/Val) directly in the terminal using plotext.
- Optionally opens an interactive Matplotlib GUI window with the accuracy plot when the script exits (--show-plot).
- Formats cycle count values in scientific notation with three decimals (e.g. 1.933e9).
- Adds +-30% random jitter to delay between output messages.
- Terminates when "[RISCV] END" is encountered.
"""

import sys
import os
import time
import random
import re
import argparse

try:
    import serial
except ImportError:
    serial = None

try:
    import plotext as plt_term
except ImportError:
    plt_term = None

import matplotlib

class UARTParserState:
    def __init__(self):
        self.n_samples = None
        self.n_epochs = None
        self.train_acc_pcts = None
        self.val_acc_pcts = None

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
        help="Base delay in seconds between printed messages (default: 1.5)"
    )
    parser.add_argument(
        "--no-plot",
        action="store_true",
        help="Disable rendering terminal plot of accuracy evolution"
    )
    parser.add_argument(
        "--save-plot",
        type=str,
        default="accuracy_evolution.png",
        help="Path to save accuracy evolution plot PNG (default: accuracy_evolution.png)"
    )
    parser.add_argument(
        "--show-plot",
        action="store_true",
        help="Open an interactive Matplotlib GUI plot window when the script finishes"
    )
    parser.add_argument(
        "--mock-file",
        type=str,
        default=None,
        help="Path to a text file to read mock UART data from instead of serial port (for testing)"
    )
    return parser.parse_args()

def sleep_with_jitter(base_delay):
    """
    Sleeps for base_delay with +-30% random variability.
    """
    if base_delay <= 0:
        return
    actual_delay = random.uniform(base_delay * 0.70, base_delay * 1.30)
    time.sleep(actual_delay)

def extract_numeric_tokens(numbers_str):
    """
    Parses a string of space-separated or comma-separated numbers into a list of floats.
    """
    tokens = re.findall(r"[-+]?\d*\.?\d+", numbers_str)
    return [float(t) for t in tokens if t]

def format_acc_value(val):
    """Formats float value nicely as percentage."""
    if val.is_integer():
        return f"{int(val)}%"
    return f"{val:.2f}%"

def format_scientific_cycles(cleaned_msg):
    """
    Converts numbers in cycle count lines into scientific notation with 3 decimals (e.g., 1.933e9).
    """
    if "cycle" in cleaned_msg.lower():
        def replace_num(match):
            prefix = match.group(1)
            num_val = float(match.group(2))
            suffix = match.group(3)
            sci_str = f"{num_val:.3e}".replace("e+0", "e").replace("e+", "e").replace("e-0", "e-")
            return f"{prefix}{sci_str}{suffix}"

        cleaned_msg = re.sub(r'(=\s*)(\d+)(\b.*)', replace_num, cleaned_msg)
    return cleaned_msg

def render_terminal_plot(train_pcts, val_pcts):
    """
    Renders terminal line plot using plotext.
    """
    if not train_pcts and not val_pcts:
        return

    if plt_term is not None:
        n_points = max(len(train_pcts or []), len(val_pcts or []))
        epochs = list(range(1, n_points + 1))

        print("\n" + "="*60, flush=True)
        print(" ACCURACY EVOLUTION ACROSS EPOCHS ".center(60, "="), flush=True)
        print("="*60, flush=True)
        plt_term.clf()
        if train_pcts:
            plt_term.plot(epochs[:len(train_pcts)], train_pcts, label="Train Acc (%)", color="cyan", marker="dot")
        if val_pcts:
            plt_term.plot(epochs[:len(val_pcts)], val_pcts, label="Val Acc (%)", color="magenta", marker="dot")

        plt_term.title("Epoch vs Accuracy (%)")
        plt_term.xlabel("Epoch")
        plt_term.ylabel("Accuracy (%)")
        plt_term.plotsize(65, 16)
        plt_term.show()
        print("="*60 + "\n", flush=True)

def export_matplotlib_plot(train_pcts, val_pcts, save_png_path=None, show_gui=False):
    """
    Saves PNG image and/or displays interactive Matplotlib plot window using matplotlib.
    """
    if not train_pcts and not val_pcts:
        return

    # If GUI display is requested, use default interactive backend; otherwise use 'Agg'
    if not show_gui:
        matplotlib.use('Agg')
    
    import matplotlib.pyplot as plt

    n_points = max(len(train_pcts or []), len(val_pcts or []))
    epochs = list(range(1, n_points + 1))

    try:
        fig, ax = plt.subplots(figsize=(8, 5))
        if train_pcts:
            ax.plot(epochs[:len(train_pcts)], train_pcts, 'o-', label="Training Accuracy (%)", color="#00bcd4")
        if val_pcts:
            ax.plot(epochs[:len(val_pcts)], val_pcts, 's-', label="Validation Accuracy (%)", color="#e91e63")

        ax.set_title("Accuracy Evolution across Epochs")
        ax.set_xlabel("Epoch")
        ax.set_ylabel("Accuracy (%)")
        ax.set_ylim(0, 105)
        ax.grid(True, linestyle="--", alpha=0.6)
        ax.legend(loc="lower right")
        fig.tight_layout()

        if save_png_path:
            fig.savefig(save_png_path, dpi=150)
            print(f"Saved accuracy plot image to: {save_png_path}")

        if show_gui:
            print("Opening Matplotlib plot window... (Close plot window to finish)")
            plt.show()

        plt.close(fig)
    except Exception as e:
        print(f"Warning: Matplotlib plot error: {e}", file=sys.stderr)

def process_line(line_str, log_file, delay, state, enable_plot=True, save_png_path=None, show_gui=False):
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

        # Render accuracy plots upon exit
        if enable_plot and (state.train_acc_pcts or state.val_acc_pcts):
            render_terminal_plot(state.train_acc_pcts, state.val_acc_pcts)
            export_matplotlib_plot(state.train_acc_pcts, state.val_acc_pcts, save_png_path, show_gui)

        sleep_with_jitter(delay)
        return True

    # Check for NSAMP and NEPOCHS configuration line
    nsamp_match = re.search(r'NSAMP\s*[:=]?\s*(\d+)', line_str, re.IGNORECASE)
    nepochs_match = re.search(r'NEPOCHS\s*[:=]?\s*(\d+)', line_str, re.IGNORECASE)

    if nsamp_match and nepochs_match:
        state.n_samples = int(nsamp_match.group(1))
        state.n_epochs = int(nepochs_match.group(1))
        # Do NOT print this line, return False without sleeping
        return False

    # Check for accuracy output lists (TRAINACC / VALACC)
    acc_match = re.search(
        r'\[RISCV\]\s*(TRAINACC|VALACC|TRAIN|VAL)\s*(?:IN\s+\d+\s+EPOCHS)?:?\s*(.*)',
        line_str,
        re.IGNORECASE
    )

    if acc_match:
        tag_type = acc_match.group(1).upper()
        numbers_str = acc_match.group(2)
        raw_counts = extract_numeric_tokens(numbers_str)

        if raw_counts:
            # Convert raw correct sample counts to percentage if NSAMP is known
            if state.n_samples and state.n_samples > 0:
                pct_values = [(c / state.n_samples) * 100.0 for c in raw_counts]
            else:
                pct_values = raw_counts

            if "TRAIN" in tag_type:
                state.train_acc_pcts = pct_values
            else:
                state.val_acc_pcts = pct_values

            best_acc = max(pct_values)
            avg_acc = sum(pct_values) / len(pct_values)

            label = "Training" if "TRAIN" in tag_type else "Validation"
            print(
                f"{label} Accuracy -> Best: {format_acc_value(best_acc)}, Average: {format_acc_value(avg_acc)}",
                flush=True
            )

            sleep_with_jitter(delay)
            return False

    # For standard [RISCV] messages (excluding raw accuracy lists and NSAMP config):
    cleaned_msg = re.sub(r'\[RISCV\]\s*', '', line_str).strip()
    if cleaned_msg:
        # Convert cycle numbers to scientific notation if present
        cleaned_msg = format_scientific_cycles(cleaned_msg)
        print(cleaned_msg, flush=True)
        # sleep_with_jitter(delay)

    return False

def main():
    args = parse_args()
    state = UARTParserState()

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
    enable_plot = not args.no_plot
    save_png_path = args.save_plot
    show_gui = args.show_plot

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
                    is_end = process_line(line_str, log_file, delay, state, enable_plot, save_png_path, show_gui)
                    if is_end:
                        print("Reached [RISCV] END. Terminating script.")
                        break
        else:
            if serial is None:
                print("Error: 'pyserial' package is not installed in the current environment.", file=sys.stderr)
                sys.exit(1)

            try:
                # Try opening serial port (exclusive=False allows opening even if non-exclusive locks exist)
                try:
                    ser = serial.Serial(port_arg, baud_arg, timeout=1.0, exclusive=False)
                except TypeError:
                    # Fallback for older pyserial versions without exclusive argument
                    ser = serial.Serial(port_arg, baud_arg, timeout=1.0)
            except Exception as e:
                print(f"Error opening serial port '{port_arg}': {e}", file=sys.stderr)
                if "busy" in str(e).lower() or "errno 16" in str(e).lower():
                    print("\n[HINT] 'Device or resource busy' means another process (like screen, minicom, or ModemManager) is currently holding the port open.", file=sys.stderr)
                    print("Please close screen or kill the process using the port before running this script:", file=sys.stderr)
                    print("  - To exit screen: press Ctrl+A then K (or Ctrl+A then \\)", file=sys.stderr)
                    print("  - Or kill screen sessions: killall screen", file=sys.stderr)
                sys.exit(1)

            try:
                while True:
                    line_bytes = ser.readline()
                    if not line_bytes:
                        continue
                    line_str = line_bytes.decode('utf-8', errors='replace').rstrip('\r\n')
                    is_end = process_line(line_str, log_file, delay, state, enable_plot, save_png_path, show_gui)
                    if is_end:
                        print("Training completed, terminating script.")
                        break
            except KeyboardInterrupt:
                print("\nInterrupted by user. Exiting.")
            finally:
                ser.close()

if __name__ == "__main__":
    main()
