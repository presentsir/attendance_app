from machine import Pin, I2C
import ssd1306
from time import sleep
from keypad import KeyPad
import bluetooth
from micropython import const
import struct

# Helper function to create advertisement payload
def advertising_payload(name, services=None, appearance=0):
    payload = bytearray()
    def _append(adv_type, value):
        payload.append(len(value) + 1)
        payload.append(adv_type)
        payload.extend(value)
    # Flags: general discoverable mode, BR/EDR not supported.
    _append(0x01, b'\x06')
    # Complete Local Name.
    if name:
        _append(0x09, name.encode())
    # Services.
    if services:
        for uuid in services:
            b = bytes(uuid)
            if len(b) == 2:
                _append(0x03, b)
            elif len(b) == 16:
                _append(0x07, b)
    # Appearance (optional).
    if appearance:
        _append(0x19, struct.pack("<h", appearance))
    return payload

# Initialize hardware I2C for OLED.
i2c = I2C(0, scl=Pin(21), sda=Pin(22))
print("I2C devices found:", [hex(d) for d in i2c.scan()])

# Initialize OLED display
oled = ssd1306.SSD1306_I2C(128, 64, i2c)

# Bluetooth setup
_IRQ_CENTRAL_CONNECT    = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2)
_IRQ_GATTS_WRITE        = const(3)

# Custom service UUID for ESP32 Attendance
UART_UUID = bluetooth.UUID('6E400001-B5A3-F393-E0A9-E50E24DCCA9E')
UART_TX   = (bluetooth.UUID('6E400003-B5A3-F393-E0A9-E50E24DCCA9E'), bluetooth.FLAG_NOTIFY)
UART_RX   = (bluetooth.UUID('6E400002-B5A3-F393-E0A9-E50E24DCCA9E'), bluetooth.FLAG_WRITE)
UART_SERVICE = (UART_UUID, (UART_TX, UART_RX,))

# Device name
DEVICE_NAME = 'ESP32-Attendance'

class BLEAttendance:
    def __init__(self):
        self.ble = bluetooth.BLE()
        self.ble.active(True)
        self.ble.irq(self.ble_irq)
        ((self.tx_handle, self.rx_handle),) = self.ble.gatts_register_services((UART_SERVICE,))
        self.connected = False
        self.register_services()
        self.advertise()

    def register_services(self):
        # Increase the size of the rx buffer and enable append mode.
        self.ble.gatts_set_buffer(self.rx_handle, 100, True)
        self.ble.gatts_write(self.rx_handle, bytes(100))

    def ble_irq(self, event, data):
        if event == _IRQ_CENTRAL_CONNECT:
            self.connected = True
            oled.fill(0)
            oled.text('Connected to app', 0, 0)
            oled.show()
            print('Connected to app')
        elif event == _IRQ_CENTRAL_DISCONNECT:
            self.connected = False
            oled.fill(0)
            oled.text('Disconnected', 0, 0)
            oled.text('Advertising...', 0, 16)
            oled.show()
            print('Disconnected')
            self.advertise()
        elif event == _IRQ_GATTS_WRITE:
            buffer = self.ble.gatts_read(self.rx_handle)
            message = buffer.decode().strip()
            print('Received:', message)
            oled.fill(0)
            oled.text('Received:', 0, 0)
            oled.text(message, 0, 16)
            oled.show()

    def advertise(self):
        # Only include the device name (omit services to reduce payload length)
        adv_data = advertising_payload(name=DEVICE_NAME)
        self.ble.gap_advertise(100, adv_data)
        print('Advertising...')

    def send(self, data):
        if self.connected:
            self.ble.gatts_notify(0, self.tx_handle, data)

# Initialize Bluetooth
ble_attendance = BLEAttendance()

# Initialize keypad
rows = [Pin(13, Pin.OUT), Pin(12, Pin.OUT), Pin(14, Pin.OUT), Pin(27, Pin.OUT)]
cols = [
    Pin(26, Pin.IN, Pin.PULL_DOWN),
    Pin(25, Pin.IN, Pin.PULL_DOWN),
    Pin(33, Pin.IN, Pin.PULL_DOWN),
    Pin(32, Pin.IN, Pin.PULL_DOWN)
]

keypad_layout = [
    ['1', '2', '3', 'A'],
    ['4', '5', '6', 'B'],
    ['7', '8', '9', 'C'],
    ['*', '0', '#', 'D']
]

keypad = KeyPad(rows, cols, keypad_layout)

# Initial OLED display
oled.fill(0)
oled.text('ESP32 Attendance', 0, 0)
oled.text('Advertising...', 0, 16)
oled.show()

# Main loop
while True:
    if keypad.scan():
        key = keypad.get_key()
        if key:
            print('Key pressed:', key)
            if ble_attendance.connected:
                ble_attendance.send(key.encode())
            oled.fill(0)
            oled.text('Key: ' + key, 0, 0)
            if ble_attendance.connected:
                oled.text('Sent to app', 0, 16)
            oled.show()
    sleep(0.1)
