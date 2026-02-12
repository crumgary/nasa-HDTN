import socket
import time

def main():
    target_ip = "127.0.0.1"
    target_port = 6565
    
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    print(f"Sending UDP packets to {target_ip}:{target_port}...")
    
    seq = 0
    
    try:
        while True:
            message = f"Hello HDTN (Seq: {seq})"
            sock.sendto(message.encode('utf-8'), (target_ip, target_port))
            print(f"Sent: {message}")
            
            seq += 1
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nStopping sender.")
    finally:
        sock.close()

if __name__ == "__main__":
    main()
