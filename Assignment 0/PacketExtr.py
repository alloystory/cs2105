import sys

if __name__ == "__main__":
    while True:
        header = sys.stdin.buffer.read1(6)
        if len(header) == 0:
            break
        
        num_bytes = 0
        while True:
            data = sys.stdin.buffer.read1(1).decode()
            if data == "B":
                break
            num_bytes = num_bytes * 10 + int(data)
        
        while num_bytes > 0:
            packet = sys.stdin.buffer.read1(min(num_bytes, 1 * 1024 * 1024))
            sys.stdout.buffer.write(packet)
            sys.stdout.buffer.flush()
            num_bytes -= len(packet)