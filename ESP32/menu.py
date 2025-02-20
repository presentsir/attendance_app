from machine import Pin, I2C
from ssd1306 import SSD1306_I2C
import time
import attendance
import transfer

# Initialize OLED
i2c = I2C(0, scl=Pin(21), sda=Pin(22))  # SCL on D21, SDA on D22
oled = SSD1306_I2C(128, 64, i2c)  # Initialize OLED display

# Keypad setup
rows = [Pin(13, Pin.OUT), Pin(12, Pin.OUT), Pin(14, Pin.OUT), Pin(27, Pin.OUT)]  # Rows: D13, D12, D14, D27
cols = [Pin(26, Pin.IN, Pin.PULL_DOWN), Pin(25, Pin.IN, Pin.PULL_DOWN), Pin(33, Pin.IN, Pin.PULL_DOWN), Pin(32, Pin.IN, Pin.PULL_DOWN)]  # Columns: D26, D25, D33, D32

# Keypad layout
keypad = [
    ['1', '2', '3', 'A'],
    ['4', '5', '6', 'B'],
    ['7', '8', '9', 'C'],
    ['*', '0', '#', 'D']
]

# Menu options
menu_options = ["Take Attendance", "Transfer File"]
current_option = 0  # Start with the first option

# Function to read keypad
def read_keypad():
    for row_index, row_pin in enumerate(rows):
        row_pin.value(1)  # Set current row to HIGH
        for col_index, col_pin in enumerate(cols):
            if col_pin.value() == 1:  # Check if column is HIGH
                time.sleep(0.2)  # Debounce delay
                while col_pin.value() == 1:  # Wait for key release
                    pass
                row_pin.value(0)  # Reset row to LOW
                return keypad[row_index][col_index]
        row_pin.value(0)  # Reset row to LOW
    return None

# Function to display a message on OLED
def display_message(message, x=0, y=0, clear=True):
    if clear:
        oled.fill(0)
    oled.text(message, x, y)
    oled.show()

# Function to display the menu
def display_menu():
    display_message("Select Option:", 0, 0)
    display_message(f"> {menu_options[current_option]}", 0, 20, clear=False)

# Main function
def main():
    global current_option

    while True:
        display_menu()  # Show the menu
        key = read_keypad()  # Read keypad input

        if key == 'C':  # Backward (previous option)
            current_option = (current_option - 1) % len(menu_options)
        elif key == 'D':  # Forward (next option)
            current_option = (current_option + 1) % len(menu_options)
        elif key == '#':  # Enter (select option)
            if current_option == 0:  # Take Attendance
                display_message("Starting Attendance...", 0, 0)
                time.sleep(1)
                # Inside menu.py
                attendance.main()  # Ensure no arguments are passed

            elif current_option == 1:  # Transfer File
                display_message("Starting Transfer...", 0, 0)
                time.sleep(1)
                transfer.main()  # Run transfer.py

# Run the program
if __name__ == "__main__":
    main()
