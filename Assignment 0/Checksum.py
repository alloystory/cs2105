import sys
from zlib import crc32

if __name__ == "__main__":
    with open(sys.argv[1], "rb") as f:
        checksum = crc32(f.read())
        print(checksum)