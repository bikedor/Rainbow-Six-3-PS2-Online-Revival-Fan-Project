import socket
import time

# Exact UDP payload from your LAN capture (SSRVINFO packet that advertised "Cinema" / "DOR")
RAW_PACKET = bytes.fromhex(
    "53535256494e464f000000006df8785b2d7fa4b83d2bd4b4ffffffff04000000010000000a00000000000000494e49303100083d43696e656d61003e000038430000404300008042000080430000c04200b0083d444f52000000000000000000000000000000000012f50e430000863c"
)

def broadcast(packet: bytes, port: int = 1001):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    sock.sendto(packet, ("<broadcast>", port))
    sock.close()

if __name__ == "__main__":
    print(f"Broadcasting exact captured SSR VINFO packet ({len(RAW_PACKET)} bytes) on UDP 1001...")
    while True:
        broadcast(RAW_PACKET)
        time.sleep(1.0)