import 'package:js/js.dart';
import 'package:uuid/uuid.dart';
import 'skyway_stab.dart' as stab;

@JS('newPeer')
external void _newPeer(String key, int debug, Function(String) onOpenCallback);

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

@JS('sendData')
external void _sendData(String data);

@JS('leaveRoom')
external void _leaveRoom();

class SkyWayHelper {
  SkyWayHelper({this.useStab = false});

  final bool useStab;
  final peerId = const Uuid().v4();

  void newPeer(String key, int debug, Function(String) onOpenCallback) {
    if (useStab) {
      stab.newPeer(peerId, key, debug, allowInterop(onOpenCallback));
    } else {
      _newPeer(key, debug, allowInterop(onOpenCallback));
    }
  }

  void joinRoom(
      String roomId,
      String mode,
      Function() onOpenCallback,
      Function(String) onPeerJoinCallback,
      Function() onStreamCallback,
      Function(String, String) onDataCallback,
      Function(String) onPeerLeave,
      Function() onClose) {
    if (useStab) {
      stab.joinRoom(
          peerId,
          roomId,
          mode,
          allowInterop(onOpenCallback),
          allowInterop(onPeerJoinCallback),
          allowInterop(onStreamCallback),
          allowInterop(onDataCallback),
          allowInterop(onPeerLeave),
          allowInterop(onClose));
    } else {
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
  }

  void sendData(String data) {
    if (useStab) {
      stab.sendData(peerId, data);
    } else {
      _sendData(data);
    }
  }

  void leaveRoom() {
    final func = useStab ? stab.leaveRoom : _leaveRoom;
    if (useStab) {
      stab.leaveRoom(peerId);
    } else {
      _leaveRoom();
    }
  }
}
