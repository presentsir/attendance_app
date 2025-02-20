import network
import socket
import time
from machine import Pin

# Function to start HTTP server
def start_http_server():
    # Set up Wi-Fi hotspot
    ap = network.WLAN(network.AP_IF)
    ap.active(True)
    ap.config(essid="AttendanceDevice", password="12345678")
    print("Hotspot: AttendanceDevice")
    print("Password: 12345678")

    # Start HTTP server
    addr = socket.getaddrinfo('0.0.0.0', 80)[0][-1]
    server_socket = socket.socket()
    server_socket.bind(addr)
    server_socket.listen(1)
    print("Server running...")

    while True:
        client, addr = server_socket.accept()
        request = client.recv(1024)
        request = str(request)

        # Serve the attendance.json file
        if "GET /attendance.json" in request:
            try:
                with open("attendance.json", "r") as file:
                    data = file.read()
                client.send("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n")
                client.send(data)
            except Exception as e:
                client.send("HTTP/1.1 500 Internal Server Error\r\n\r\n")
                print("Error serving file:", e)
        else:
            client.send("HTTP/1.1 404 Not Found\r\n\r\n")

        client.close()

# Main function
def main():
    start_http_server()

# Run the program
if __name__ == "__main__":
    main()
