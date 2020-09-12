import socket
import sys

class WebServer:
    def __init__(self, host = "127.0.0.1", port = 8888):
        self.db = Database()
        self.host = host
        self.port = port

    def start(self):
        try:
            server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server_sock.bind((self.host, self.port))
            server_sock.listen()
            print("The server is listening at {}:{}".format(self.host, self.port))
            
            while True:
                try:
                    client_sock, client_address = server_sock.accept()
                    while True:
                        request = Request(self.db, client_sock)
                        response = request.process()
                        if not response:
                            break
                        client_sock.send(response.to_bytes())
                finally:
                    client_sock.close()
        finally:
            server_sock.close()

class Request:
    def __init__(self, db, socket):
        self.db = db
        self.socket = socket

    def process(self):
        header = self.read_header()
        if not header:
            return None
        
        if "/key/" == header["path"][:5]:
            return self.route_keyvals(header)
        elif "/counter/" == header["path"][:9]:
            return self.route_counters(header)

    def route_keyvals(self, header):
        key = header["path"][5:]
        if header["method"] == "post":
            content_length = int(header["other"]["content-length"])
            body = self.read_body(content_length)
            self.db.update_keyval(key, body)
            return Response(200)
        elif header["method"] == "get":
            data = self.db.get_keyval(key)
            if data == None:
                return Response(404)
            return Response(200, data)
        elif header["method"] == "delete":
            data = self.db.del_keyval(key)
            if data == None:
                return Response(404)
            return Response(200, data)

    def route_counters(self, header):
        key = header["path"][9:]
        if header["method"] == "post":
            self.db.update_counter(key)
            return Response(200)
        elif header["method"] == "get":
            data = self.db.get_counter(key)
            if data == None:
                return Response(200, b"0")
            return Response(200, str(data).encode())
    
    def read_header(self):
        # Reading Header
        header = []
        substring = []
        while True:
            data = self.socket.recv(1)
            if not data:
                break
            data = data.decode()
            if data != " ":
                substring.append(data)
            elif data == " " and substring:
                header.append("".join(substring))
                substring = []
            else:
                break

        # Parsing Header
        parsed_header = {}
        if header:
            parsed_header["method"] = header[0].lower()
            parsed_header["path"] = header[1]
            parsed_header["other"] = {}
            for i in range(2, len(header) - 1, 2):
                parsed_header["other"][header[i].lower()] = header[i + 1]
        return parsed_header

    def read_body(self, content_length):
        content = bytes()
        while content_length > 0:
            data = self.socket.recv(content_length)
            if not data:
                break
            content += data
            content_length -= len(data)
        return content

class Response:
    REF_STATUS_CODE = {
        200: "OK",
        404: "NotFound"
    }

    def __init__(self, status_code, data = None):
        self.status_code = status_code
        self.status_msg = self.REF_STATUS_CODE[status_code]
        self.headers = {}
        self.data = data
        if data != None:
            self.headers["content-length"] = len(self.data)

    def to_bytes(self):
        output = "{} {}".format(self.status_code, self.status_msg)
        for key, val in self.headers.items():
            output += " {} {}".format(key, val)
        output = (output + "  ").encode()
        
        if self.data != None:
            output = output + self.data
        return output

class Database:
    def __init__(self):
        self.keyvals = {}
        self.counters = {}

    def update_keyval(self, key, value):
        self.keyvals[key] = value

    def get_keyval(self, key):
        return self.keyvals.get(key)

    def del_keyval(self, key):
        return self.keyvals.pop(key, None)
    
    def update_counter(self, key):
        if key not in self.counters:
            self.counters[key] = 0
        self.counters[key] += 1

    def get_counter(self, key):
        return self.counters.get(key)

if __name__ == "__main__":
    if len(sys.argv) != 2 or not sys.argv[1].isdigit():
        print("Usage: python3 WebServer-A0134202B.py <port>")
        exit(1)
    WebServer(port = int(sys.argv[1])).start()