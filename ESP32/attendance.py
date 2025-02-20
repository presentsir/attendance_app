from machine import Pin, I2C
from ssd1306 import SSD1306_I2C
import time
import json
import os

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

# Function to list all JSON files (classes)
def list_json_files():
    files = os.listdir()
    json_files = [file for file in files if file.endswith(".json")]
    return json_files

# Function to select a class
def select_class(json_files):
    current_index = 0
    while True:
        display_message("Select Class:", 0, 0)
        display_message(f"> {json_files[current_index]}", 0, 20, clear=False)
        key = read_keypad()
        if key == 'C':  # Backward (previous class)
            current_index = (current_index - 1) % len(json_files)
        elif key == 'D':  # Forward (next class)
            current_index = (current_index + 1) % len(json_files)
        elif key == '#':  # Enter (select class)
            return json_files[current_index]

# Function to mark attendance for a class
def mark_attendance(class_file):
    # Load class data
    with open(class_file, "r") as file:
        class_data = json.load(file)

    # Mark attendance for each student
    for student in class_data:
        display_message(f"RNO: {student['rno']}", 0, 0)
        display_message(f"Name: {student['name']}", 0, 20, clear=False)
        display_message("A:Present B:Absent", 0, 40, clear=False)
        while True:
            key = read_keypad()
            if key == 'A':  # Present
                student['attendance'] = "Present"
                break
            elif key == 'B':  # Absent
                student['attendance'] = "Absent"
                break
        display_message(f"RNO: {student['rno']}", 0, 0)
        display_message(f"Status: {student['attendance']}", 0, 20, clear=False)
        time.sleep(1)  # Delay for better UX

    # Save updated class data
    with open(class_file, "w") as file:
        json.dump(class_data, file)
    display_message("Attendance saved!", 0, 0)
    time.sleep(2)

# Main function
def main():
    # List all JSON files (classes)
    json_files = list_json_files()
    if not json_files:
        display_message("No classes found!", 0, 0)
        time.sleep(2)
        return

    # Select a class
    selected_class = select_class(json_files)

    # Mark attendance for the selected class
    mark_attendance(selected_class)

    # Redirect to menu.py
    import menu
    menu.main()

# Run the program
if __name__ == "__main__":
    main()
