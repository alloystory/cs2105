from socket import *

try:
    serverName = '127.0.0.1'
    serverPort = 8888
    clientSocket = socket(AF_INET, SOCK_STREAM)
    clientSocket.connect((serverName, serverPort))

    commands = [
        "GET /key/ModuleCode  ",
        "POST /key/ModuleCode Content-Length 6  CS2105",
        "GET /key/ModuleCode  ",
        "GET /counter/StudentNumber  ",
        "POST /counter/StudentNumber  ",
        "GET /counter/StudentNumber  "
    ]

    results = [
        "404 NotFound  ",
        "200 OK  ",
        "200 OK content-length 6  CS2105",
        "200 OK content-length 1  0",
        "200 OK  ",
        "200 OK content-length 1  1"
    ]

    error = False
    for i in range(len(commands)):
        clientSocket.send(commands[i].encode())
        result = clientSocket.recv(1024)
        if result.decode() != results[i]:
            print("[{}] - [{}]".format(result.decode(), results[i]))
            error = True
    print("Has Error:", error)
finally:
    clientSocket.close()
