import 'package:js/js.dart';

@JS('newPeer')
external void _newPeer(String key, int debug, Function(String) onOpenCallback);

void newPeer(String key, int debug, Function(String) onOpenCallback) {
  _newPeer(key, debug, allowInterop(onOpenCallback));
}

@JS('joinRoom')
external void _joinRoom(
    String roomId,
    String mode,
    Function() onOpenCallback,
    Function(String) onPeerJoinCallback,
    Function() onStreamCallback,
    Function(String, String) onDataCallback,
    Function(String) onPeerLeave,
    Function() onClose);

void joinRoom(
    String roomId,
    String mode,
    Function() onOpenCallback,
    Function(String) onPeerJoinCallback,
    Function() onStreamCallback,
    Function(String, String) onDataCallback,
    Function(String) onPeerLeave,
    Function() onClose) {
  _joinRoom(
      roomId,
      mode,
      allowInterop(onOpenCallback),
      allowInterop(onPeerJoinCallback),
      allowInterop(onStreamCallback),
      allowInterop(onDataCallback),
      allowInterop(onPeerLeave),
      allowInterop(onClose));
}

@JS('sendData')
external void sendData(String data);

@JS('leaveRoom')
external void leaveRoom();
