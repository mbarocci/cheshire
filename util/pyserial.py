import serial
import time
import argparse

# Set up argument parser
parser = argparse.ArgumentParser(description="Serial communication script")
parser.add_argument("port", help="Serial port to connect to")
parser.add_argument("baudrate", type=int, help="Baud rate for the serial connection")
args = parser.parse_args()

# Open the serial connection
ser = serial.Serial(
    port=args.port,
    baudrate=args.baudrate,
    bytesize=serial.EIGHTBITS,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    xonxoff=False,
    rtscts=False,
    dsrdtr=False,
)

print("Serial connection opened. Waiting for data...")

try:
    # Read and print the initial message
    initial_message = ser.read_until(b'\n').decode('ascii')
    print(initial_message, end='')

    # Read and print the prompt
    prompt = ser.read_until(b'\n').decode('ascii')
    print(prompt, end='')

    # Get user input and send it to the device
    user_input = input()
    ser.write(user_input.encode('ascii') + b'\r\n')

    # Read and print the echoed input
    echoed_input = ser.read_until(b'\n').decode('ascii')
    print(echoed_input, end='')

    # Read and print the final message
    final_message = ser.read_until(b'\n').decode('ascii')
    print(final_message, end='')

except KeyboardInterrupt:
    print("\nExiting...")

finally:
    ser.close()
    print("Serial connection closed.")
