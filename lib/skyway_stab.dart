import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

final random = math.Random();
final onPeerJoinCallbackMap = <String, Function(String)>{};
final onDataCallbackMap = <String, Function(String, String)>{};
final onPeerLeaveMap = <String, Function(String)>{};
final onCloseMap = <String, Function()>{};
final tcpClientMap = <String, TcpClient>{};

Duration _rduration(int range, [int offset = 1]) {
  return Duration(seconds: random.nextInt(range) + offset);
}

void newPeer(
    String peerId, String key, int debug, Function(String) onOpenCallback) {
  Timer(_rduration(1), () => onOpenCallback(peerId));
}

void joinRoom(
    String peerId,
    String roomId,
    String mode,
    Function() onOpenCallback,
    Function(String) onPeerJoinCallback,
    Function() onStreamCallback,
    Function(String, String) onDataCallback,
    Function(String) onPeerLeave,
    Function() onClose) {
  Timer(_rduration(1, 1), () => onOpenCallback());

  /*
  for (final e in onPeerJoinCallbackMap.entries) {
    Timer(_rduration(1, 1), () => e.value(peerId));
  }
  onPeerJoinCallbackMap[peerId] = onPeerJoinCallback;
  onDataCallbackMap[peerId] = onDataCallback;
   */
  tcpClientMap[peerId] = TcpClient();
  tcpClientMap[peerId]!.joinRoom(peerId, onPeerJoinCallback, onDataCallback);

  onPeerLeaveMap[peerId] = onPeerLeave;
  onCloseMap[peerId] = onClose;
}

void sendData(String peerId, String data) {
  /*
  for (final e in onDataCallbackMap.entries) {
    if (e.key != peerId) Timer(_rduration(1, 0), () => e.value(data, peerId));
  }
   */
  tcpClientMap[peerId]!.sendData(peerId, data);

}

void leaveRoom(String peerId) {
  onPeerJoinCallbackMap.remove(peerId);
  onDataCallbackMap.remove(peerId);
  onPeerLeaveMap.remove(peerId);
  for (final e in onPeerLeaveMap.entries) {
    Timer(_rduration(2, 0), () => e.value(peerId));
  }
  onCloseMap.remove(peerId)!();
}

class TcpClient {
  WebSocketChannel? _channel;
  Function(String)? _onPeerJoinCallback;
  Function(String, String)? _onDataCallback;

  void joinRoom(String peerId, Function(String) onPeerJoinCallback,
      Function(String, String) onDataCallback) {
    _onPeerJoinCallback = onPeerJoinCallback;
    _onDataCallback = onDataCallback;

    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:9999'));
    _channel?.stream.listen((message) {
      _onData(message);
    });

    final dataMap = {
      'cmd': 'joinRoom',
      'peerId': peerId,
    };
    _channel?.sink.add(json.encode(dataMap));
  }

  void sendData(String peerId, String data) {
    final dataMap = {
      'cmd': 'sendData',
      'peerId': peerId,
      'data': data,
    };
    _channel?.sink.add(json.encode(dataMap));
  }

  void _onData(String message) {
    final dataMap = jsonDecode(message) as Map<String, dynamic>;
    final cmd = dataMap['cmd'] as String;
    if (cmd == 'onPeerJoinCallback') {
      _onPeerJoinCallback!(dataMap['peerId']);
    }
    if (cmd == 'onDataCallback') {
      final data = dataMap['data'] as String;
      _onDataCallback!(data, dataMap['peerId']);
    }
  }

  void close() {
    _channel?.sink.close(status.goingAway);
  }
}
