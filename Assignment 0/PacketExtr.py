import sys

if __name__ == "__main__":
    if sys.stdin.buffer.read1(6).decode() != "Size: ":
        raise Exception("Wrong header")
    num_bytes = 0
    while True:
        data = sys.stdin.buffer.read1(1).decode()
        if data == "B":
            break
        num_bytes = num_bytes * 10 + int(data)
    
    while num_bytes > 0:
        packet = sys.stdin.buffer.read1(min(num_bytes, 1 * 1024 * 1024))
        print(packet)
        num_bytes -= len(packet)