import sys
from socket import socket, AF_INET, SOCK_DGRAM, timeout as TimeoutException
from zlib import crc32

class Utils:
    # Format: checksum (4B) |seq*10 + ack (1B) |data (59B)
    MAX_BYTES = 64
    HEADER_LENGTH = 5

    @staticmethod
    def check_segment(segment):
        checksum = int.from_bytes(segment[:4], byteorder = sys.byteorder)
        checksum_input = segment[4:]

        try:
            return crc32(checksum_input) == checksum
        except Exception:
            return False

    @staticmethod
    def split_segment(segment):
        checksum = int.from_bytes(segment[:4], byteorder = sys.byteorder)
        seq_ack = int.from_bytes(segment[4:5], byteorder = sys.byteorder)
        data = segment[5:].decode()
        return {
            "checksum": checksum,
            "seq_num": seq_ack // 10,
            "ack": bool(seq_ack % 10),
            "data": data
        }

    @staticmethod
    def prepare_segment(seq_num = 0, ack = 0, data = None):
        segment = (seq_num * 10 + ack).to_bytes(1, byteorder = sys.byteorder)
        if data != None:
            segment += data

        checksum = crc32(segment).to_bytes(4, byteorder = sys.byteorder)
        segment = checksum + segment
        return segment

class Alice:
    def __init__(self, dst_port):
        self.send_addr = ("127.0.0.1", dst_port)

    def read_from_stdin(self):
        num_bytes = Utils.MAX_BYTES - Utils.HEADER_LENGTH
        data = bytearray()
        while num_bytes > 0:
            msg = sys.stdin.buffer.read1(num_bytes)
            if len(msg) == 0:
                break
            data.extend(msg)
            num_bytes -= len(msg)
        return data

    def start(self):
        sock = socket(AF_INET, SOCK_DGRAM)
        sock.settimeout(50e-3)
        seq_num = 0
        data = self.read_from_stdin()
        
        while True:
            try:
                if len(data) == 0:
                    break
                data_segment = Utils.prepare_segment(seq_num = seq_num, data = data)
                sock.sendto(data_segment, self.send_addr)
                
                ack_segment, recv_addr = sock.recvfrom(Utils.MAX_BYTES)
                if Utils.check_segment(ack_segment):
                    chunks = Utils.split_segment(ack_segment)
                    if not chunks["ack"]:
                        continue
                    ack_seq_num = chunks["seq_num"]
                    if ack_seq_num == seq_num:
                        data = self.read_from_stdin()
                        seq_num = 1 - seq_num
            except TimeoutException:
                pass

        sock.close()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 Alice.py <unreliNetPort>")
        exit(1)
    Alice(int(sys.argv[1])).start()