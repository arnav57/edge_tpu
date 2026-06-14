import socket
import time

# FPGA Configuration
FPGA_IP = "192.168.1.128" 
MESSAGE = b"Speed... I am speed" # The goat

while(True):
    fpga_port = int(input("Enter the Instruction Index to send to TPU:\n>>  "))
    
    print(f"Sending packet to {FPGA_IP}:{fpga_port}...")

    # Create a UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(2.0) # 2-second timeout if the FPGA ghosts us

    try:
        # Send the packet and start the timer
        start_time = time.perf_counter()
        sock.sendto(MESSAGE, (FPGA_IP, fpga_port))
        
        # Wait for the FPGA to bounce it back
        data, addr = sock.recvfrom(1024)
        end_time = time.perf_counter()
        
        print(f"\n[SUCCESS] Received reply from {addr[0]}:{addr[1]}")
        print(f"Payload: {data.decode('utf-8', errors='ignore')}")
        print(f"Round-trip latency: {(end_time - start_time) * 1000:.3f} ms")
        
    except socket.timeout:
        print("\n[FAIL] Timeout! The PC sent the packet, but the FPGA didn't bounce it back.")
    finally:
        sock.close()