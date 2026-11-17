#!/usr/bin/env python3
"""Query the local Minecraft status protocol without logging in."""
import json, socket, struct
def varint(n):
    out=b''
    while True:
        part=n&127; n>>=7
        out+=bytes([part|(128 if n else 0)])
        if not n:return out
def read_varint(sock):
    value=0
    for shift in range(0,35,7):
        b=sock.recv(1)
        if not b:raise EOFError("Connection closed")
        value|=(b[0]&127)<<shift
        if not b[0]&128:return value
    raise ValueError("Invalid VarInt")
def read_exact(sock,size):
    result=b''
    while len(result)<size:
        data=sock.recv(size-len(result))
        if not data:raise EOFError("Connection closed")
        result+=data
    return result
host=b'localhost'
handshake=varint(0)+varint(47)+varint(len(host))+host+struct.pack('>H',25565)+varint(1)
with socket.create_connection(('127.0.0.1',25565),timeout=10) as sock:
    sock.sendall(varint(len(handshake))+handshake+b'\x01\x00')
    read_varint(sock)
    if read_varint(sock)!=0:raise ValueError("Unexpected packet")
    status=json.loads(read_exact(sock,read_varint(sock)))
print(json.dumps({'version':status['version'],'players':status['players'],'description':status.get('description')},indent=2))
if status['version']['protocol']!=47:raise SystemExit('Unexpected Minecraft protocol version')
