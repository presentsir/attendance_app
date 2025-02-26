# keypad.py
from machine import Pin
from time import sleep_ms

class KeyPad:
    def __init__(self, row_pins, col_pins, keys):
        self.row_pins = [Pin(pin, Pin.OUT) for pin in row_pins]
        self.col_pins = [Pin(pin, Pin.IN, Pin.PULL_DOWN) for pin in col_pins]
        self.keys = keys
        self.current_key = None

    def scan(self):
        # Set all rows low.
        for row in self.row_pins:
            row.value(0)
        # Activate one row at a time.
        for i, row in enumerate(self.row_pins):
            row.value(1)
            sleep_ms(1)  # Small delay for stability.
            # Check each column.
            for j, col in enumerate(self.col_pins):
                if col.value():
                    self.current_key = self.keys[i][j]
                    return True
            row.value(0)
        self.current_key = None
        return False

    def get_key(self):
        return self.current_key

