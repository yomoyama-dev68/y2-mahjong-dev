from websocket_server import WebsocketServer
import logging
import json

def handleJoinRoom(server, client, peerId: str):
    print("handleJoinRoom:", peerId)
    server.id_map[client['id']] =peerId
    rdata = {'cmd': 'onPeerJoinCallback',
             'peerId': peerId}
    rdata = json.dumps(rdata)
    server.send_message(rdata, client)


def handleSendData(server, client, peerId: str, data: str):
    rdata = {'cmd': 'onDataCallback',
             'peerId': peerId,
             'data': data,}
    rdata = json.dumps(rdata)
    server.send_message(rdata, client)


def handleData(server, client, data):
    data = json.loads(data)
    print("handleData:", data)
    cmd = data['cmd']
    if cmd == 'joinRoom':
        handleJoinRoom(server, client, data['peerId'])
    if cmd == 'sendData':
        handleSendData(server, client, data['peerId'], data['data'])


def handlePeerLeave(server, client):
    peerId = server.id_map.pop(client['id'])
    print(f'handlePeerLeave: {peerId}')
    rdata = {'cmd': 'onPeerLeaveCallback',
             'peerId': peerId,}
    rdata = json.dumps(rdata)
    server.send_message(rdata, client)


class Websocket_Server():

    def __init__(self, host, port):
        self.server = WebsocketServer(port, host=host, loglevel=logging.DEBUG)
        self.clients = []
        self.id_map = {}

    # クライアント接続時に呼ばれる関数
    def new_client(self, client, server):
        print("new client connected and was given id {}".format(client['id']))
        self.clients.append(client)

    # クライアント切断時に呼ばれる関数
    def client_left(self, client, server):
        print("client({}) disconnected!!".format(client['id']))
        self.clients.remove(client)
        handlePeerLeave(self, client)

    # クライアントからメッセージを受信したときに呼ばれる関数
    def message_received(self, client, server, message):
        print("client({}) said: {}".format(client['id'], message))
        handleData(self, client, message)

    # クライアントにメッセージを送信
    def send_message(self, message, ignore_client):
        print("send_message", message)
        for client in self.clients:
            if client != ignore_client:
                self.server.send_message(client, message)

    # サーバーを起動する
    def run(self):
        # クライアント接続時のコールバック関数にself.new_client関数をセット
        self.server.set_fn_new_client(self.new_client)
        # クライアント切断時のコールバック関数にself.client_left関数をセット
        self.server.set_fn_client_left(self.client_left)

    # メッセージ受信時のコールバック関数にself.message_received関数をセット
        self.server.set_fn_message_received(self.message_received) 
        self.server.run_forever()

IP_ADDR = "localhost" # IPアドレスを指定
PORT=9999 # ポートを指定
ws_server = Websocket_Server(IP_ADDR, PORT)
ws_server.run()