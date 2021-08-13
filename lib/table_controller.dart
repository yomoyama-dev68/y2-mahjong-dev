import 'dart:io';

import 'commad_handler.dart';

_toListInt(List<dynamic> obj) {
  return (obj).map((e) => e as int).toList();
}

_toListCalledTiles(List<dynamic> obj) {
  return (obj)
      .map((e) => CalledTiles.fromJsonMap(e as Map<String, dynamic>))
      .toList();
}

class TileInfo {
  TileInfo(int tileId) {
    if (tileId < 0) {
      type = 4;
      number = 0;
    } else {
      const tilesQuantityWithOutTupai = 4 * 9 * 3;
      final tupai = tileId > tilesQuantityWithOutTupai;
      type = tupai ? 3 : tileId ~/ (4 * 9); // 0:萬子, 1:筒子, 2,:索子, 3:字牌
      number = tupai
          ? (tileId - tilesQuantityWithOutTupai) % 7
          : tileId % 9; // 萬子, 筒子, 索子:9種 字牌: 7種
    }
  }

  late int type; // 0:萬子, 1:筒子, 2,:索子, 3:字牌, 4:伏牌
  late int number; // [萬子, 筒子, 索子]: 9種, [字牌]: 7種, [伏牌] 1種
}

class CalledTiles {
  CalledTiles(
      this.calledTile, this.calledFrom, this.selectedTiles, this.callAs);

  factory CalledTiles.fromJsonMap(Map<String, dynamic> map) {
    return CalledTiles(map["calledTile"] as int, map["calledFrom"] as String,
        map["selectedTiles"] as List<int>, map["callAs"] as String);
  }

  final int calledTile;
  final String calledFrom;
  final List<int> selectedTiles;
  final String callAs;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map["calledTile"] = calledTile;
    map["calledFrom"] = calledFrom;
    map["selectedTiles"] = selectedTiles;
    map["callAs"] = callAs;
    return map;
  }

  bool canLateKanWith(int tile) {
    if (selectedTiles.length != 3) return false;
    final number = TileInfo(tile).number;
    for (final selectedTile in selectedTiles) {
      if (number != TileInfo(selectedTile).number) return false;
    }
    return true;
  }
}

class PlayerData {
  PlayerData(this.name);

  factory PlayerData.fromJsonMap(Map<String, dynamic> map) {
    final data = PlayerData(map["name"]);
    data.score = map["score"] as int;
    data.tiles.addAll(_toListInt(map["tiles"]));
    data.drawnTile.addAll(_toListInt(map["drawnTile"]));
    data.discardedTiles.addAll(_toListInt(map["discardedTiles"]));
    data.calledTiles.addAll(_toListCalledTiles(map["calledTiles"]));
    data.calledTilesByOther.addAll(_toListInt(map["calledTilesByOther"]));
    data.calledTilesByOther.addAll(_toListInt(map["calledTilesByOther"]));
    return data;
  }

  final String name;
  int score = 2500;

  final List<int> drawnTile = []; // 引いてきた牌
  final List<int> tiles = []; // 持ち牌
  final List<int> discardedTiles = []; // 捨て牌
  final List<CalledTiles> calledTiles = []; // 鳴き牌
  final List<int> calledTilesByOther = []; // 鳴かれた牌
  final List<int> riichiTile = []; // リーチ牌

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map["name"] = name;
    map["score"] = score;
    map["drawnTile"] = drawnTile;
    map["tiles"] = tiles;
    map["discardedTiles"] = discardedTiles;
    map["calledTiles"] = calledTiles.map((v) => v.toMap()).toList();
    map["calledTilesByOther"] = calledTilesByOther;
    map["riichiTile"] = riichiTile;

    return map;
  }
}

class TableState {
  static const notSetup = "notSetup";
  static const doingSetupHand = "doingSetupHand";
  static const doneSetupHand = "doneSetupHand";

  static const drawable = "drawable";
  static const waitToDiscard = "waitToDiscard";

  static const selectingTilesForPong = "selectingTilesForPong";
  static const selectTilesForChow = "selectTilesForChow";
  static const waitToDiscardForPongOrChow = "waitToDiscardForPongOrChow";

  static const selectingTilesForOpenKan = "selectingTilesForOpenKan";
}


class TableData {
  // 荘中関連
  Map<String, PlayerData> playerDataMap = {}; // 親順ソート済み
  int leaderChangeCount = -1; // 局数: 0~3:東場, 4~7:南場,
  int leaderContinuousCount = 0; // 場数（親継続数）

  // 局中関連
  String state = TableState.notSetup;
  String turnedPeerId = "";
  List<int> wallTiles = []; // 山牌　tile: 牌
  List<int> deadWallTiles = []; // 王牌
  List<int> replacementTiles = []; // 嶺上牌

  int lastDiscardedTile = -1;
  String lastDiscardedPlayerPeerID = "";
  int countOfKan = 0;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map["playerDataMap"] =
        playerDataMap.map((key, value) => MapEntry(key, value.toMap()));
    map["leaderChangeCount"] = leaderChangeCount;
    map["leaderContinuousCount"] = leaderContinuousCount;

    map["state"] = state;
    map["turnedPeerId"] = turnedPeerId;
    map["wallTiles"] = wallTiles;
    map["deadWallTiles"] = deadWallTiles;
    map["replacementTiles"] = replacementTiles;

    map["lastDiscardedTile"] = lastDiscardedTile;
    map["lastDiscardedPlayerPeerID"] = lastDiscardedPlayerPeerID;
    map["countOfKan"] = countOfKan;

    return map;
  }

  void applyData(Map<String, dynamic> map) {
    playerDataMap = (map["playerDataMap"] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, PlayerData.fromJsonMap(value)));

    leaderChangeCount = map["leaderChangeCount"] as int;
    leaderContinuousCount = map["leaderContinuousCount"] as int;

    state = map["state"] as String;
    turnedPeerId = map["turnedPeerId"] as String;
    wallTiles = _toListInt(map["wallTiles"]);
    deadWallTiles = _toListInt(map["deadWallTiles"]);
    replacementTiles = _toListInt(map["replacementTiles"]);

    lastDiscardedTile = map["lastDiscardedTile"] as int;
    lastDiscardedPlayerPeerID = map["lastDiscardedPlayerPeerID"] as String;
    countOfKan = map["countOfKan"] as int;
  }

  List<String> idList() {
    return playerDataMap.keys.toList();
  }

  int direction(String from, String to) {
    final index0 = idList().indexOf(from);
    int index1 = idList().indexOf(to);
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

  PlayerData? playerData(String peerId) {
    return playerDataMap[peerId];
  }
}

class Table extends TableData {
  Table(this._updateTableListener);

  final Function() _updateTableListener;

  void startGame(Map<String, String> member) {
    // メンバーの順番を乱数でシャッフルする。
    final shuffled = <String, String>{};
    for (final id in member.keys.toList()..shuffle()) {
      shuffled[id] = member[id]!;
    }

    // プレイヤーデータを作成する。
    for (final member in shuffled.entries) {
      playerDataMap[member.key] = PlayerData(member.value);
    }
  }

  void nextLeader() {
    assert(playerDataMap.length == 4);
    leaderChangeCount += 1;
    leaderContinuousCount = 0;
    _updateTableListener();
    _setupHand();
  }

  void previousLeader() {
    if (leaderChangeCount > 0) leaderChangeCount -= 1;
    leaderContinuousCount = 0;
    _updateTableListener();
    _setupHand();
  }

  void continueLeader() {
    leaderContinuousCount += 1;
    _updateTableListener();
  }

  List<int> _createShuffledTiles() {
    final tiles = <int>[];
    // 萬子, 筒子, 索子:9種 字牌: 7種　それぞれが4枚ずつ。
    for (var i = 0; i < (9 * 3 + 7) * 4; i++) {
      tiles.add(i);
    }
    tiles.shuffle();
    return tiles;
  }

  Future<void> _setupHand() async {
    state = "doingSetupHand";
    final allTiles = _createShuffledTiles();
    replacementTiles = allTiles.sublist(0, 4);
    deadWallTiles = allTiles.sublist(4, 14);
    wallTiles = allTiles.sublist(14);
    _updateTableListener();
    for (var i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 2));
      for (final peerId in idList()) {
        final tiles = <int>[];
        tiles.add(wallTiles.removeLast());
        tiles.add(wallTiles.removeLast());
        tiles.add(wallTiles.removeLast());
        tiles.add(wallTiles.removeLast());
        if (i == 2) tiles.add(wallTiles.removeLast());
        playerDataMap[peerId]!.tiles.addAll(tiles);
      }
      _updateTableListener();
    }
    await Future.delayed(const Duration(seconds: 2));
    _turnTo(idList()[0]);
    state = "drawable";
    _updateTableListener();
  }

  String _nextPeerId(String peerId) {
    final index = (idList().indexOf(peerId) + 1) % 4;
    return idList()[index];
  }

  void _nextTurn(String peerId) {
    if (wallTiles.isEmpty) {
      drawnGame();
    } else {
      _turnTo(_nextPeerId(peerId));
    }
  }

  void _turnTo(String peerId) {
    turnedPeerId = peerId;
  }

  CommandResult handleDrawTileCmd(String peerId) {
    if (turnedPeerId != peerId) {
      return CommandResult(CommandResultStateCode.refuse, "not your turn.");
    }
    if (state != "drawable") {
      return CommandResult(
          CommandResultStateCode.refuse, "not drawable state.");
    }

    print("handleDrawTileCmd: ${peerId}: ${wallTiles}");
    if (wallTiles.isEmpty) {
      return CommandResult(CommandResultStateCode.error, "wallTiles is empty.");
    }

    final data = playerData(peerId);
    if (data == null) {
      return CommandResult(
          CommandResultStateCode.error, "player data is null.");
    }
    if (data.drawnTile.isNotEmpty) {
      return CommandResult(
          CommandResultStateCode.error, "drawnTile is not empty.");
    }

    final drawnTile = wallTiles.removeLast();
    data.drawnTile.add(drawnTile);

    state = "waitToDiscard";
    _updateTableListener();
    return CommandResult(CommandResultStateCode.ok, "");
  }

  CommandResult handleDiscardTileCmd(String peerId, int tile) {
    if (turnedPeerId != peerId) {
      return CommandResult(CommandResultStateCode.error, "not your turn.");
    }
    final discardableState = ["waitToDiscard", "selectingTilesForOpenKan"];
    if (!discardableState.contains(state)) {
      return CommandResult(
          CommandResultStateCode.error, "not discardable state.");
    }

    final data = playerData(peerId);
    if (data == null) {
      return CommandResult(
          CommandResultStateCode.error, "player data is null.");
    }

    data.tiles.addAll(data.drawnTile);
    if (!data.tiles.contains(tile)) {
      return CommandResult(
          CommandResultStateCode.error, "discarded tile not in your tiles.");
    }

    data.tiles.remove(tile);
    data.discardedTiles.add(tile);

    lastDiscardedTile = tile;
    lastDiscardedPlayerPeerID = turnedPeerId;

    // 明槓の場合は 打牌後にドラをめくる。
    if (state == "selectingTilesForOpenKan") {
      countOfKan += 1;
    }
    state = "drawable";
    _nextTurn(turnedPeerId);
    _updateTableListener();
    return CommandResult(CommandResultStateCode.ok, "");
  }

  CommandResult cmdPong(String peerId) {
    if (turnedPeerId == peerId) {
      return CommandResult(CommandResultStateCode.refuse, "in your turn.");
    }
    if (state != "drawable") {
      return CommandResult(
          CommandResultStateCode.refuse, "not drawable state.");
    }

    state = "selectingTilesForPong";
    _turnTo(peerId);
    _updateTableListener();

    return CommandResult(CommandResultStateCode.ok, "");
  }

  CommandResult cmdSelectedTilesForPongOrChow(
      String peerId, List<int> selectedTiles) {
    if (turnedPeerId != peerId) {
      return CommandResult(CommandResultStateCode.error, "not your turn.");
    }
    final selectingState = ["selectingTilesForPong", "selectTilesForChow"];
    if (selectingState.contains(state)) {
      return CommandResult(
          CommandResultStateCode.error, "not selecting state.");
    }
    if (selectedTiles.length != 2) {
      return CommandResult(
          CommandResultStateCode.error, "bad selected tiles quantity.");
    }

    state = "waitToDiscardForPongOrChow";
    _setSelectedTiles(peerId, selectedTiles, "pong-chow");

    return CommandResult(CommandResultStateCode.ok, "");
  }

  CommandResult cmdOpenKan(String peerId) {
    if (turnedPeerId != peerId) {
      return CommandResult(CommandResultStateCode.error, "not your turn.");
    }
    if (state == "drawable") {
      return CommandResult(CommandResultStateCode.error, "not drawable state.");
    }

    state = "selectingTilesForOpenKan";
    _turnTo(peerId);
    _updateTableListener();
    return CommandResult(CommandResultStateCode.ok, "");
  }

  CommandResult cmdCloseKan(String peerId) {
    if (turnedPeerId != peerId) {
      return CommandResult(CommandResultStateCode.error, "not your turn.");
    }
    state = "selectingTilesForCloseKan";
    _updateTableListener();
    return CommandResult(CommandResultStateCode.ok, "");
  }

  CommandResult cmdLateKan(String peerId) {
    if (turnedPeerId != peerId) {
      return CommandResult(CommandResultStateCode.error, "not your turn.");
    }
    state = "selectingTilesForLateKan";
    _updateTableListener();
    return CommandResult(CommandResultStateCode.ok, "");
  }

  CommandResult cmdSetSelectedTilesForOpenKan(
      String peerId, List<int> selectedTiles) {
    if (turnedPeerId != peerId) {
      return CommandResult(CommandResultStateCode.error, "not your turn.");
    }
    final selectingState = ["selectingTilesForOpenKan"];
    if (selectingState.contains(state)) {
      return CommandResult(
          CommandResultStateCode.error, "not selecting state.");
    }
    if (selectedTiles.length != 3) {
      return CommandResult(
          CommandResultStateCode.error, "bad selected tiles quantity.");
    }

    final data = playerData(peerId);
    if (data == null) {
      return CommandResult(
          CommandResultStateCode.error, "player data is null.");
    }

    _setSelectedTiles(peerId, selectedTiles, "open-kan");

    data.drawnTile.add(replacementTiles.removeLast()); // 嶺上牌を手牌に移動する。
    wallTiles.removeAt(0); // 山牌の牌を一つ消す。

    return CommandResult(CommandResultStateCode.ok, "");
  }

  CommandResult cmdSetSelectedTilesForCloseKan(
      String peerId, List<int> selectedTiles) {
    if (turnedPeerId != peerId) {
      return CommandResult(CommandResultStateCode.error, "not your turn.");
    }
    final selectingState = ["selectingTilesForCloseKan"];
    if (selectingState.contains(state)) {
      return CommandResult(
          CommandResultStateCode.error, "not selecting state.");
    }
    if (selectedTiles.length != 4) {
      return CommandResult(
          CommandResultStateCode.error, "bad selected tiles quantity.");
    }

    final data = playerData(peerId);
    if (data == null) {
      return CommandResult(
          CommandResultStateCode.error, "player data is null.");
    }

    // 鳴き牌登録
    data.calledTiles.add(CalledTiles(-1, peerId, selectedTiles, "close-kan"));
    // 鳴き牌を持ち牌から除外
    for (final tile in selectedTiles) {
      data.tiles.remove(tile);
    }

    data.drawnTile.add(replacementTiles.removeLast()); // 嶺上牌を手牌に移動する。
    wallTiles.removeAt(0); // 山牌の牌を一つ消す。
    countOfKan += 1;

    state = "waitToDiscardForCloseKan";
    return CommandResult(CommandResultStateCode.ok, "");
  }

  CommandResult cmdSetSelectedTilesForLateKan(String peerId, tile) {
    if (turnedPeerId != peerId) {
      return CommandResult(CommandResultStateCode.error, "not your turn.");
    }
    final selectingState = ["selectingTilesForCloseKan"];
    if (selectingState.contains(state)) {
      return CommandResult(
          CommandResultStateCode.error, "not selecting state.");
    }

    final data = playerData(peerId);
    if (data == null) {
      return CommandResult(
          CommandResultStateCode.error, "player data is null.");
    }

    var targetIndex = -1;
    for (var i = 0; i < data.calledTiles.length; i++) {
      if (data.calledTiles[i].canLateKanWith(tile)) {
        targetIndex = i;
      }
    }
    if (targetIndex < 0) {
      return CommandResult(
          CommandResultStateCode.error, "not selecting state.");
    }

    // ポンした刻子を小明槓にして入れ直す。
    final pongTiles = data.calledTiles[targetIndex];
    final selectedTiles = <int>[...pongTiles.selectedTiles, tile];
    final lateKanTiles = CalledTiles(
        pongTiles.calledTile, pongTiles.calledFrom, selectedTiles, "late-kan");
    data.calledTiles[targetIndex] = lateKanTiles;
    // 鳴き牌を持ち牌から除外
    data.tiles
      ..addAll(data.drawnTile)
      ..remove(tile);

    data.drawnTile.add(replacementTiles.removeLast()); // 嶺上牌を手牌に移動する。
    wallTiles.removeAt(0); // 山牌の牌を一つ消す。

    state = "waitToDiscardForLateKan";
    return CommandResult(CommandResultStateCode.ok, "");
  }

  void _setSelectedTiles(
      String peerId, List<int> selectedTiles, String callAs) {
    // 鳴き牌を持ち牌から除外
    final data = playerData(peerId);
    assert(data != null);
    if (data == null) return;

    for (final tile in selectedTiles) {
      data.tiles.remove(tile);
    }

    // 鳴き牌登録
    data.calledTiles.add(CalledTiles(
        lastDiscardedTile, lastDiscardedPlayerPeerID, selectedTiles, callAs));

    // 鳴先に対して鳴かれた牌登録
    final otherData = playerDataMap[lastDiscardedPlayerPeerID]!;
    otherData.calledTilesByOther.add(lastDiscardedTile);
  }

  void drawnGame() {
    // 流局
    state = "drawGame";
    turnedPeerId = "";
  }
}
