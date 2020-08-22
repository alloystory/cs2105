import sys
from zlib import crc32

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 Checksum.py <filepath>")
        exit(1)

    with open(sys.argv[1], "rb") as f:
        checksum = crc32(f.read())
        print(checksum)