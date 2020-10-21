import sys
from socket import socket, AF_INET, SOCK_DGRAM
from Alice import Utils

class Bob:
    def __init__(self, recv_port):
        self.recv_addr = ("127.0.0.1", recv_port)

    def start(self):
        sock = socket(AF_INET, SOCK_DGRAM)
        sock.bind(self.recv_addr)
        last_ack_seq_num = 0
        expected_seq_num = 0

        while True:
            data_segment, recv_addr = sock.recvfrom(Utils.MAX_BYTES)
            if Utils.check_segment(data_segment):
                chunks = Utils.split_segment(data_segment)
                seq_num = chunks["seq_num"]
                last_ack_seq_num = seq_num

                if seq_num == expected_seq_num:
                    print(chunks["data"], end = "")
                    expected_seq_num = 1 - seq_num
                
            ack_segment = Utils.prepare_segment(ack = 1, seq_num = last_ack_seq_num)
            sock.sendto(ack_segment, recv_addr)
        sock.close()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 Bob.py <rcvPort>")
        exit(1)
    Bob(int(sys.argv[1])).start()