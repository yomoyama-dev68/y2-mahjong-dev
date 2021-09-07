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
  SkyWayHelper({this.useStab=false});
  final bool useStab;
  final peerId = const Uuid().v4();

  void newPeer(String key, int debug, Function(String) onOpenCallback) {
    final func = useStab ? stab.newPeer : _newPeer;
    // func(peerId, key, debug, allowInterop(onOpenCallback));
    func(key, debug, allowInterop(onOpenCallback));
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
    final func = useStab ? stab.joinRoom : _joinRoom;
    /*
    func(
        peerId,
        roomId,
        mode,
        allowInterop(onOpenCallback),
        allowInterop(onPeerJoinCallback),
        allowInterop(onStreamCallback),
        allowInterop(onDataCallback),
        allowInterop(onPeerLeave),
        allowInterop(onClose));
     */
    func(
        roomId,
        mode,
        allowInterop(onOpenCallback),
        allowInterop(onPeerJoinCallback),
        allowInterop(onStreamCallback),
        allowInterop(onDataCallback),
        allowInterop(onPeerLeave),
        allowInterop(onClose));
  }

  void sendData(String data) {
    final func = useStab ? stab.sendData : _sendData;
    func(peerId, data);
  }

  void leaveRoom() {
    final func = useStab ? stab.leaveRoom : _leaveRoom;
    func(peerId);
  }
}