import socket

def main():
    listen_ip = "0.0.0.0"
    listen_port = 8554
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((listen_ip, listen_port))
    
    print(f"Listening for UDP packets on {listen_ip}:{listen_port}...")
    
    try:
        while True:
            data, addr = sock.recvfrom(4096)
            try:
                message = data.decode('utf-8')
                print(f"Received from {addr}: {message}")
            except UnicodeDecodeError:
                print(f"Received binary data from {addr} (length: {len(data)})")
                
    except KeyboardInterrupt:
        print("\nStopping receiver.")
    finally:
        sock.close()

if __name__ == "__main__":
    main()
