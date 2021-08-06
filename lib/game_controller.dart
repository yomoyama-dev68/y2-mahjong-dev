import 'dart:convert';

class SkyWayUtil {
  static Map<String, String> parameter() {
    return {"key": "value"};
  }

  static String newPeer() {
    return "PeerId";
  }

  static String newRoom() {
    return "RoomId";
  }

  static void joinRoom(
    String peerId,
    String roomId,
    Function() onOpen,
    Function(String) onPeerJoin,
    Function(String, String) onData,
  ) {}

  static void sendData(String data) {}
}

enum CallState {
  notCalling,
  isCalling,
  accepted,
  pauseForOther,
}

/*
class GameController {
  static const _keyRoomId = "roomId";
  final _peerIdList = <String>[];

  late String myPeerId;
  late String roomId;
  String myName = "???";
  bool isRoomOwner = false;
  CallState callState = CallState.notCalling;
  Table? table;

  GameController(Function(String) invitationSender) {
    myPeerId = SkyWayUtil.newPeer();
    final param = SkyWayUtil.parameter();
    if (param.containsKey(_keyRoomId)) {
      roomId = param[_keyRoomId]!;
    } else {
      roomId = SkyWayUtil.newRoom();
      invitationSender(roomId);
      isRoomOwner = true;
    }

    SkyWayUtil.joinRoom(myPeerId, roomId, onOpen, onPeerJoin, onData);
  }

  void onOpen() {
    print("onOpen $myPeerId, $roomId");
  }

  void onPeerJoin(String peerId) {
    print("onPeerJoin $peerId");
    _peerIdList.add(peerId);
    if (isRoomOwner && _peerIdList.length == 3) {
      startGame();
    }
  }

  void onData(String peerId, String jsonData) {
    print("onPeerJoin $peerId");
    final data = json.decode(jsonData);
    final cmd = data["cmd"];
    final args = data["args"] as Map<String, dynamic>;
    if (cmd == "setName") {
      _fromOtherOnSetName(peerId, args["name"] as String);
    }

    if (cmd == "callAny") {
      onCall(args);
    }

    if (cmd == "acceptCall") {
      onAcceptCall(args);
    }
  }

  void setName(String name) {
    myName = name;
    final data = {
      "cmd": "setName",
      "args": {"name": name}
    };
    SkyWayUtil.sendData(json.encode(data));
  }

  void _fromOtherOnSetName(String peerId, String name) {}

  void callAny() {
    assert(callState == CallState.notCalling);

    callState = CallState.isCalling;
    final data = {
      "cmd": "callAny",
      "args": {"peerId": myPeerId}
    };
    SkyWayUtil.sendData(json.encode(data));
  }

  void onCall(Map<String, dynamic> args) {
    // Callの受諾はルームオーナーのみ可能
    if (isRoomOwner) {
      final peerId = args["peerId"]!;
      if (callState == CallState.notCalling) {
        acceptCall(true, peerId);
      } else {
        acceptCall(false, peerId);
      }
    }
  }

  void acceptCall(bool accept, String peerId) {
    assert(isRoomOwner);
    final data = {
      "cmd": "acceptCall",
      "args": {"accept": accept, "peerId": peerId}
    };
    SkyWayUtil.sendData(json.encode(data));
  }

  void onAcceptCall(Map<String, dynamic> args) {
    if (myPeerId == args["peerId"]!) {
      callState == CallState.accepted;
    } else {
      callState == CallState.pauseForOther;
    }
  }

  void endCall(bool endHand) {
    assert(callState == CallState.accepted);
    final data = {
      "cmd": "endCall",
      "args": {"peerId": myPeerId, "endHand": endHand}
    };
    SkyWayUtil.sendData(json.encode(data));
  }

  void cancelCall() {
    assert(callState == CallState.accepted);
    final data = {
      "cmd": "cancelCall",
      "args": {"peerId": myPeerId}
    };
    SkyWayUtil.sendData(json.encode(data));
  }

  void onEndCall(Map<String, dynamic> args) {
    if (isRoomOwner) {
      final endHand = args["endHand"]! as bool;
      if (endHand) {
        onEndHand(false);
      } else {
        final peerId = args["peerId"]! as String;
      }
    }
  }

  void onEndHand(bool exhaustiveDraw) {}

  void discardTile(int tile) {
    final data = {
      "cmd": "discardTile",
      "args": {"peerId": myPeerId, "tile": tile}
    };
    SkyWayUtil.sendData(json.encode(data));
  }

  void onDiscardTile(Map<String, dynamic> args) {
    if (isRoomOwner) {
      final peerId = args["peerId"]! as String;
      turnPlayer(nextPlayer(peerId));
    }
  }

  void turnPlayer(String peerId) {
    assert(isRoomOwner);

    final data = {
      "cmd": "turnPlayer",
      "args": {"turnPlayerPeerId": peerId}
    };
    SkyWayUtil.sendData(json.encode(data));
  }

  void onTurnPlayer(Map<String, dynamic> args) {
    final turnPlayerPeerId = args["turnPlayerPeerId"]! as String;
    if (myPeerId == turnPlayerPeerId) {}
  }

  void drawTile() {
    final data = {
      "cmd": "drawTile",
      "args": {"peerId": myPeerId}
    };
    SkyWayUtil.sendData(json.encode(data));
  }

  void onDrawTile(Map<String, dynamic> args) {
    if (isRoomOwner) {
      final peerId = args["peerId"]! as String;
    }
  }

  void drewTile(String peerId) {
    assert(isRoomOwner);
    final tile = table.drawTile();
    final data = {
      "cmd": "drewTile",
      "args": {"peerId": peerId, "data": tile}
    };
    SkyWayUtil.sendData(json.encode(data));
  }

  void onDrewTile(Map<String, dynamic> args) {}

  void startGame() {}

  void _nextHand() {
    // Hand: 局
  }
}
*/

class Table {
  Table(Map<String, String> members) {
    for (final member in members.entries) {
      playerDataMap[member.key] = PlayerData(member.value);
    }
    peerIdList = playerDataMap.keys.toList();
  }

  final Map<String, PlayerData> playerDataMap = {}; // 親順ソート済み
  late List<String> peerIdList;

  int leaderIndex = 0;
  int leaderContinuousCount = 0;

  // For this hand. state
  List<int> wallTiles = []; // 山牌　tile: 牌
  List<int> deadWallTiles = []; // 王牌

  bool isRoomOwner = true;
  String myPeerId = "";
  String turnedPeerId = "";
  String mode = ""; // ["pon", "drawGame", "endGame"]
  int lastDiscardedTile = -1;
  String lastDiscardedPlayerPeerID = "";
  int countOfKan = 0;

  List<int> createShuffledTiles() {
    final tiles = <int>[];
    // 萬子, 筒子, 索子:9種 字牌: 7種　それぞれが4枚ずつ。
    for (var i = 0; i < (9 * 3 + 7)* 4; i) {
      tiles.add(i);
    }
    tiles.shuffle();
    return tiles;
  }

  void nextLeader() {
    leaderIndex += 1;
    leaderContinuousCount = 0;
  }

  void previousLeader() {
    leaderIndex -= 1;
    leaderContinuousCount = 0;
  }

  void continueLeader() {
    leaderContinuousCount += 1;
  }

  void setupHand() {
    assert(isRoomOwner);
    final allTiles = createShuffledTiles();
    deadWallTiles = allTiles.sublist(0, 14);
    wallTiles = allTiles.sublist(14);

    for (var i = 0; i < 4 * 3; i++) {
      final tiles = <int>[];
      tiles.add(wallTiles.removeLast());
      tiles.add(wallTiles.removeLast());
      tiles.add(wallTiles.removeLast());
      tiles.add(wallTiles.removeLast());
      final index = (i + leaderIndex) % 4;
      playerDataMap[peerIdList[index]]!.tiles.addAll(tiles);
      sendAllPlayerData();
    }

    for (var i = 0; i < 4; i++) {
      final tiles = <int>[];
      tiles.add(wallTiles.removeLast());
      final index = (i + leaderIndex) % 4;
      playerDataMap[peerIdList[index]]!.tiles.addAll(tiles);
      sendAllPlayerData();
    }
  }

  void sendAllPlayerData() {}

  String nextPeerId(String peerId) {
    final index = (peerIdList.indexOf(peerId) + 1) % 4;
    return peerIdList[index];
  }

  void nextTurn(String peerId) {
    if (wallTiles.isEmpty) {
      drawnGame();
    } else {
      turnTo(nextPeerId(peerId));
    }
  }

  void turnTo(String peerId) {
    turnedPeerId = peerId;
  }

  bool isTurned() {
    return turnedPeerId == myPeerId;
  }

  PlayerData myData() {
    return playerDataMap[myPeerId]!;
  }

  void drawTile() {
    assert(isTurned());
    assert(mode == "");
    final drawnTile = wallTiles.removeLast();
    myData().drewTile.add(drawnTile);
    mode = "waitToDiscard";
    sendAllPlayerData();
  }

  void discardTile(int tile) {
    assert(isTurned());
    myData()
      ..tiles.addAll(myData().drewTile)
      ..tiles.remove(tile)
      ..discardedTiles.add(tile);

    lastDiscardedTile = tile;
    lastDiscardedPlayerPeerID = turnedPeerId;

    // 明槓の場合は 打牌後にドラをめくる。
    if (mode == "selectTilesForKan") {
      countOfKan += 1;
    }
    mode = "";
    nextTurn(turnedPeerId);
    sendAllPlayerData();
  }

  void pong() {
    mode = "selectTilesForPong";
    turnTo(myPeerId);
    sendAllPlayerData();
  }

  void chow() {
    mode = "selectTilesForChow";
    turnTo(myPeerId);
    sendAllPlayerData();
  }

  void cancelForPongOrChow() {
    assert(isTurned());
    // 最後に牌を捨てた人の次の人にターンを回す。
    mode = "";
    nextTurn(lastDiscardedPlayerPeerID);
  }

  void selectTilesForPongOrChow(List<int> selectedTiles) {
    assert(isTurned());
    assert(selectedTiles.length == 2);

    selectTilesCommon(selectedTiles, "PongOrChow");

    mode = "waitToDiscardForPongOrChow";
    sendAllPlayerData();
  }

  void kan() {
    mode = "selectTilesForKan";
    turnTo(myPeerId);
    sendAllPlayerData();
  }

  void selfKan() {
    assert(isTurned());

    mode = "selectTilesForSelfKan";
    turnTo(myPeerId);
    sendAllPlayerData();
  }

  void selectTilesForKan(List<int> selectedTiles) {
    assert(isTurned());
    assert(selectedTiles.length == 3);

    selectTilesCommon(selectedTiles, "kan");
    kanCommon();

    mode = "waitToDiscardForKan";
    sendAllPlayerData();
  }

  void selectTilesForSelfKan(List<int> selectedTiles) {
    assert(isTurned());
    assert(selectedTiles.length == 4);

    selectTilesCommon(selectedTiles, "selfKan");
    kanCommon();
    countOfKan += 1;

    mode = "waitToDiscardForSelfKan";
    sendAllPlayerData();
  }

  void kanCommon() {
    // 王牌からドロー。
    final tile = deadWallTiles.removeAt(0);
    // 山牌の牌を王牌に移動する。
    deadWallTiles.add(wallTiles.removeAt(0));
  }

  void selectTilesCommon(List<int> selectedTiles, String callAs) {
    // 鳴き牌を持ち牌から除外
    final _myData = myData();
    for (final tile in selectedTiles) {
      _myData.tiles.remove(tile);
    }

    // 鳴き牌登録
    _myData.calledTiles.add(CalledTiles(
        lastDiscardedTile, lastDiscardedPlayerPeerID, selectedTiles, callAs));

    // 鳴先に対して鳴かれた牌登録
    final otherData = playerDataMap[lastDiscardedPlayerPeerID]!;
    otherData.calledTilesByOther.add(lastDiscardedTile);
  }

  void drawnGame() {
    // 流局
    mode = "drawGame";
    turnedPeerId = "";
    sendAllPlayerData();
  }

  int direction(String from, String to) {
    final index0 = peerIdList.indexOf(from);
    int index1 = peerIdList.indexOf(to);
    if (index1 < index0) {
      index1 += 4;
    }
    //  0,   1,   2,   3,
    // i0,   1,   2,   3,
    // -1,  i0,   1,   2 |  3,  i0,   1,   2
    // -2,  -1,  i0,   1 |  2,   3,  i0,   1
    // -3,  -2,  -1,  i0 |  1,   2,   3,  i0
    return index1 - index0; // 0:自分, 1:右, 2:対面, 3:左
  }
}

class PlayerData {
  PlayerData(this.name);

  final String name;
  var score = 2500;

  final List<int> drewTile = []; // 引いてきた牌
  final List<int> tiles = []; // 持ち牌
  final List<int> discardedTiles = []; // 捨て牌
  final List<CalledTiles> calledTiles = []; // 鳴き牌
  final List<int> calledTilesByOther = []; // 鳴かれた牌
  final List<int> riichiTile = []; // リーチ牌
}

class CalledTiles {
  CalledTiles(this.calledTile, this.calledFrom, this.selectedTiles, this.callAs);

  final int calledTile;
  final String calledFrom;
  final List<int> selectedTiles;
  final String callAs;
}
