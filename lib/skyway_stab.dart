import 'dart:async';
import 'dart:math' as math;

final random = math.Random();
final onPeerJoinCallbackMap = <String, Function(String)>{};
final onDataCallbackMap = <String, Function(String, String)>{};
final onPeerLeaveMap = <String, Function(String)>{};
final onCloseMap = <String, Function()>{};

Duration _rduration(int range, [int offset = 1]) {
  return Duration(seconds: random.nextInt(range) + offset);
}

void newPeer(String peerId, String key, int debug, Function(String) onOpenCallback) {
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
  for (final e in onPeerJoinCallbackMap.entries) {
    Timer(_rduration(1, 1), () => e.value(peerId));
  }
  onPeerJoinCallbackMap[peerId] = onPeerJoinCallback;
  onDataCallbackMap[peerId] = onDataCallback;
  onPeerLeaveMap[peerId] = onPeerLeave;
  onCloseMap[peerId] = onClose;
}

void sendData(String peerId, String data) {
  for (final e in onDataCallbackMap.entries) {
    if (e.key != peerId) Timer(_rduration(1, 0), () => e.value(data, peerId));
  }
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
