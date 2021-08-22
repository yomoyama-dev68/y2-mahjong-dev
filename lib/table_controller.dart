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
          ? (tileId - tilesQuantityWithOutTupai) ~/ 4
          : (tileId % (4 * 9)) ~/ 4; // 萬子, 筒子, 索子:9種 字牌: 7種
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
        _toListInt(map["selectedTiles"]), map["callAs"] as String);
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
    final openTiles = [...selectedTiles, calledTile];
    final number = TileInfo(tile).number;
    for (final openTile in openTiles) {
      if (number != TileInfo(openTile).number) return false;
    }
    return true;
  }
}

class PlayerData {
  PlayerData(this.name);

  factory PlayerData.fromJsonMap(Map<String, dynamic> map) {
    final data = PlayerData(map["name"]);

    data.requestingScoreFrom.addAll(
        (map["requestingScoreFrom"] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value as int)));
    data.waitingNextHand = map["waitingNextHand"] as bool;
    data.score = map["score"] as int;
    data.openTiles = map["openTiles"];
    data.tiles.addAll(_toListInt(map["tiles"]));
    data.drawnTile.addAll(_toListInt(map["drawnTile"]));
    data.discardedTiles.addAll(_toListInt(map["discardedTiles"]));
    data.calledTiles.addAll(_toListCalledTiles(map["calledTiles"]));
    data.calledTilesByOther.addAll(_toListInt(map["calledTilesByOther"]));
    data.calledTilesByOther.addAll(_toListInt(map["calledTilesByOther"]));
    data.riichiTile.addAll(_toListInt(map["riichiTile"]));

    return data;
  }

  final String name;
  final requestingScoreFrom = <String, int>{};
  bool waitingNextHand = false;
  int score = 25000;
  bool openTiles = false;

  final List<int> drawnTile = []; // 引いてきた牌
  final List<int> tiles = []; // 持ち牌
  final List<int> discardedTiles = []; // 捨て牌
  final List<CalledTiles> calledTiles = []; // 鳴き牌
  final List<int> calledTilesByOther = []; // 鳴かれた牌
  final List<int> riichiTile = []; // リーチ牌

  void clearTiles() {
    openTiles = false;
    drawnTile.clear();
    tiles.clear();
    discardedTiles.clear();
    calledTiles.clear();
    calledTilesByOther.clear();
    riichiTile.clear();
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map["name"] = name;
    map["score"] = score;
    map["requestingScoreFrom"] = requestingScoreFrom;
    map["waitingNextHand"] = waitingNextHand;
    map["openTiles"] = openTiles;
    map["drawnTile"] = drawnTile;
    map["tiles"] = tiles;
    map["discardedTiles"] = discardedTiles;
    map["calledTiles"] = calledTiles.map((v) => v.toMap()).toList();
    map["calledTilesByOther"] = calledTilesByOther;
    map["riichiTile"] = riichiTile;

    return map;
  }
}

class NotYourTurnException implements Exception {
  NotYourTurnException([this.message = 'Not your turn.']);

  final String message;

  @override
  String toString() {
    return message;
  }
}

class RefuseException implements Exception {
  RefuseException([this.message = '']);

  final String message;

  @override
  String toString() {
    return message;
  }
}

class TableState {
  static const notSetup = "notSetup";
  static const doingSetupHand = "doingSetupHand";
  static const doneSetupHand = "doneSetupHand";

  static const drawable = "drawable";
  static const waitToDiscard = "waitToDiscard";

  static const selectingTilesForPong = "selectingTilesForPong";
  static const selectingTilesForChow = "selectTilesForChow";
  static const waitToDiscardForPongOrChow = "waitToDiscardForPongOrChow";

  static const selectingCloseOrLateKan = "selectingCloseOrLateKan";

  static const selectingTilesForOpenKan = "selectingTilesForOpenKan";
  static const selectingTilesForCloseKan = "selectingTilesForCloseKan";
  static const selectingTilesForLateKan = "selectingTilesForLateKan";

  static const waitToDiscardForOpenKan = "waitToDiscardForOpenKan";
  static const waitToDiscardForCloseKan = "waitToDiscardForCloseKan";
  static const waitToDiscardForLateKan = "waitToDiscardForLateKan";
  static const waitToDiscardWithRiichi = "waitToDiscardWithRiichi";

  static const calledRon = "calledRon";

  static const drawGame = "drawGame";
  static const processingFinishHand = "processingFinishHand";
  static const waitingNextHand = "waitingNextHand";

  static bool isSelectingTileState(state) {
    const isSelectingTileState = [
      TableState.waitToDiscard,
      TableState.waitToDiscardForPongOrChow,
      TableState.waitToDiscardForOpenKan,
      TableState.waitToDiscardForCloseKan,
      TableState.waitToDiscardForLateKan,
      TableState.selectingTilesForPong,
      TableState.selectingTilesForChow,
      TableState.selectingTilesForOpenKan,
      TableState.selectingTilesForCloseKan,
      TableState.selectingTilesForLateKan,
    ];
    return isSelectingTileState.contains(state);
  }
}

class TableData {
  // 荘中関連
  Map<String, PlayerData> playerDataMap = {}; // 親順ソート済み
  int leaderChangeCount = -1; // 局数: 0~3:東場, 4~7:南場,
  int leaderContinuousCount = 0; // 場数（親継続数）
  String lastWinner = "";
  int remainRiichiBarCounts = 0; // リーチ供託棒数

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

  bool isSelectingTileState() {
    return TableState.isSelectingTileState(state);
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

  void nextHand() {
    for (final data in playerDataMap.values) {
      data.waitingNextHand = false;
    }

    if (lastWinner == currentLeader()) {
      continueLeader();
    } else {
      nextLeader();
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
    _setupHand();
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
    state = TableState.doingSetupHand;

    for (final v in playerDataMap.values) {
      v.clearTiles();
    }

    final allTiles = _createShuffledTiles();
    replacementTiles = allTiles.sublist(0, 4);
    deadWallTiles = allTiles.sublist(4, 14);
    wallTiles = allTiles.sublist(14);
    _updateTableListener();
    for (var i = 0; i < 3; i++) {
      await Future.delayed(const Duration(seconds: 1));
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
    for (final v in playerDataMap.values) {
      v.tiles.sort();
    }
    _turnTo(currentLeader());
    state = TableState.drawable;
    _updateTableListener();
  }

  String currentLeader() {
    return idList()[leaderChangeCount % 4];
  }

  String _nextPeerId(String peerId) {
    final index = (idList().indexOf(peerId) + 1) % 4;
    return idList()[index];
  }

  void _nextTurn(String peerId) {
    if (wallTiles.isEmpty) {
      _onDrawGame(); // 流局
    } else {
      _turnTo(_nextPeerId(peerId));
    }
  }

  void _turnTo(String peerId) {
    turnedPeerId = peerId;
  }

  void _onDrawGame() async {
    state = TableState.drawGame;
    _updateTableListener();
    await Future.delayed(const Duration(seconds: 1));

    //　リーチ棒の精算
    for (final data in playerDataMap.values) {
      if (data.riichiTile.isNotEmpty) {
        remainRiichiBarCounts += 1;
        data.score -= 1000;
      }
    }

    _onFinishedHand();
  }

  void _onFinishedHand() {
    state = TableState.processingFinishHand;
    lastWinner = turnedPeerId;
    _updateTableListener();
  }

  handleCancelCall({required String peerId}) {
    _checkState(peerId, allowTableState: [
      TableState.calledRon,
      TableState.selectingTilesForPong,
      TableState.selectingTilesForChow,
      TableState.selectingTilesForOpenKan,
      TableState.selectingCloseOrLateKan,
      TableState.selectingTilesForCloseKan,
      TableState.selectingTilesForLateKan,
    ]);

    _nextTurn(lastDiscardedPlayerPeerID);
    state = TableState.drawable;
    _updateTableListener();
  }

  handleDiscardTileWithRiichi({required String peerId, required int tile}) {
    _checkState(peerId, allowTableState: [
      TableState.waitToDiscard,
      TableState.waitToDiscardForCloseKan
    ]);

    final data = playerData(peerId)!;
    data.riichiTile.add(tile);
    handleDiscardTile(peerId: peerId, tile: tile);
  }

  handleRon({required String peerId}) {
    _checkState(peerId,
        needMyTrue: false, allowTableState: [TableState.drawable]);
    state = TableState.calledRon;
    _turnTo(turnedPeerId);
    _updateTableListener();
  }

  handleFinishHand({required String peerId}) {
    _checkState(peerId, allowTableState: [
      TableState.calledRon,
      TableState.waitToDiscard,
      TableState.waitToDiscardForOpenKan,
      TableState.waitToDiscardForCloseKan,
      TableState.waitToDiscardForLateKan
    ]);

    //　リーチ棒の精算
    for (final data in playerDataMap.values) {
      if (data.riichiTile.isNotEmpty) {
        remainRiichiBarCounts += 1;
        data.score -= 1000;
      }
    }
    playerData(turnedPeerId)!.score += remainRiichiBarCounts * 1000;
    remainRiichiBarCounts = 0;

    _onFinishedHand();
  }

  handleRequestScore(
      {required String peerId, required Map<String, dynamic> request}) {
    for (final e in request.entries) {
      final data = playerData(e.key)!;
      data.requestingScoreFrom[peerId] = e.value; // Score
    }
    _updateTableListener();
  }

  handleAcceptRequestedScore({required String peerId}) {
    _checkState(peerId, needMyTrue: false);

    final data = playerData(peerId)!;
    for (final e in data.requestingScoreFrom.entries) {
      final requester = e.key;
      final score = e.value;

      final requesterData = playerData(requester)!;
      requesterData.score -= score;
      data.score += score;
    }

    data.requestingScoreFrom.clear();
    _updateTableListener();
  }

  _checkState(String peerId,
      {bool needMyTrue = true, List<String> allowTableState = const []}) {
    final data = playerData(peerId);
    if (data == null) {
      throw StateError("No Player(${peerId}) data.");
    }
    if (needMyTrue && turnedPeerId != peerId) {
      throw StateError("Not your${peerId}) turn.");
    }
    if (allowTableState.isNotEmpty && !allowTableState.contains(state)) {
      throw StateError("Not allowed state(${state}).");
    }
  }

  handleRefuseRequestedScore({required String peerId}) {
    _checkState(peerId, needMyTrue: false);
    final data = playerData(peerId)!;
    data.requestingScoreFrom.clear();
    _updateTableListener();
  }

  handleRequestNextHand({required String peerId}) {
    _checkState(peerId, needMyTrue: false);

    final data = playerData(peerId)!;
    data.waitingNextHand = true;
    _updateTableListener();

    // 全員が次局待機状態であれば次局を開始する。
    var waitingPlayerCount = 0;
    for (final v in playerDataMap.values) {
      waitingPlayerCount += v.waitingNextHand ? 1 : 0;
    }
    if (waitingPlayerCount == 4) {
      Future.delayed(const Duration(seconds: 1)).then((value) => nextHand());
    }
  }

  handleOpenTiles({required String peerId}) {
    _checkState(peerId, needMyTrue: false);
    final data = playerData(peerId)!;
    data.openTiles = !data.openTiles;
    _updateTableListener();
  }

  handleDrawTile({required String peerId}) {
    if (turnedPeerId != peerId) throw NotYourTurnException();

    _checkState(peerId, allowTableState: [TableState.drawable]);

    final data = playerData(peerId)!;
    if (data.drawnTile.isNotEmpty) {
      throw StateError("Drawn tile is not empty.");
    }
    if (wallTiles.isEmpty) {
      throw StateError("Wall tiles is empty.");
    }

    final drawnTile = wallTiles.removeLast();
    data.drawnTile.add(drawnTile);

    state = TableState.waitToDiscard;
    _updateTableListener();
  }

  handleDiscardTile({required String peerId, required int tile}) {
    _checkState(peerId, allowTableState: [
      TableState.waitToDiscard,
      TableState.waitToDiscardForPongOrChow,
      TableState.waitToDiscardForOpenKan,
      TableState.waitToDiscardForCloseKan,
      TableState.waitToDiscardForLateKan,
    ]);

    final data = playerData(peerId)!;
    data.tiles.addAll(data.drawnTile);
    data.drawnTile.clear();
    if (!data.tiles.contains(tile)) {
      throw StateError("Discard tile does not exist.");
    }

    data.tiles.remove(tile);
    data.tiles.sort();
    data.discardedTiles.add(tile);

    lastDiscardedTile = tile;
    lastDiscardedPlayerPeerID = turnedPeerId;

    // 明槓の場合は 打牌後にドラをめくる。
    if ([TableState.waitToDiscardForOpenKan, TableState.waitToDiscardForLateKan]
        .contains(state)) {
      countOfKan += 1;
    }

    _nextTurn(turnedPeerId);
    state = TableState.drawable;
    _updateTableListener();
  }

  handlePong({required String peerId}) {
    if (state != TableState.drawable) throw RefuseException("");
    state = TableState.selectingTilesForPong;
    _turnTo(peerId);
    _updateTableListener();
  }

  handleChow({required String peerId}) {
    if (state != TableState.drawable) throw RefuseException("");
    state = TableState.selectingTilesForChow;
    _turnTo(peerId);
    _updateTableListener();
  }

  handleSetSelectedTilesForPongOrChow(
      {required String peerId, required List<dynamic> selectedTiles}) {
    _checkState(peerId, allowTableState: [
      TableState.selectingTilesForPong,
      TableState.selectingTilesForChow
    ]);

    if (selectedTiles.length != 2) {
      throw ArgumentError("bad selected tiles quantity.");
    }

    _setSelectedTiles(
        peerId, selectedTiles.map((e) => e as int).toList(), "pong-chow");

    state = TableState.waitToDiscardForPongOrChow;
    _updateTableListener();
  }

  handleOpenKan({required String peerId}) {
    if (state != TableState.drawable) throw RefuseException("");
    // if (turnedPeerId == peerId) throw StateError("In your turn.");

    state = TableState.selectingTilesForOpenKan;
    _turnTo(peerId);
    _updateTableListener();
  }

  handleSelfKan({required String peerId}) {
    _checkState(peerId, allowTableState: [
      TableState.waitToDiscard,
    ]);

    state = TableState.selectingCloseOrLateKan;
    _updateTableListener();
  }

  handleCloseKan({required String peerId}) {
    _checkState(peerId, allowTableState: [
      TableState.selectingCloseOrLateKan,
    ]);
    state = TableState.selectingTilesForCloseKan;
    _updateTableListener();
  }

  handleLateKan({required String peerId}) {
    if (turnedPeerId != peerId) throw StateError("Not your turn.");
    state = TableState.selectingTilesForLateKan;
    _updateTableListener();
  }

  handleSetSelectedTilesForOpenKan(
      {required String peerId, required List<dynamic> selectedTiles}) {
    _checkState(peerId, needMyTrue: false, allowTableState: [
      TableState.selectingTilesForOpenKan,
    ]);
    if (selectedTiles.length != 3) {
      throw ArgumentError("bad selected tiles quantity.");
    }

    _setSelectedTiles(
        peerId, selectedTiles.map((e) => e as int).toList(), "open-kan");

    final data = playerData(peerId)!;
    data.drawnTile.add(replacementTiles.removeLast()); // 嶺上牌を手牌に移動する。
    wallTiles.removeAt(0); // 山牌の牌を一つ消す。

    state = TableState.waitToDiscardForOpenKan;
    _updateTableListener();
  }

  handleSetSelectedTilesForCloseKan(
      {required String peerId, required List<dynamic> selectedTiles}) {
    _checkState(peerId, allowTableState: [
      TableState.selectingTilesForCloseKan,
    ]);
    if (selectedTiles.length != 4) {
      throw ArgumentError("bad selected tiles quantity.");
    }

    final data = playerData(peerId)!;

    // 鳴き牌登録
    data.calledTiles.add(CalledTiles(
        -1, peerId, selectedTiles.map((e) => e as int).toList(), "close-kan"));
    // 鳴き牌を持ち牌から除外
    for (final tile in selectedTiles) {
      data.tiles.remove(tile);
    }

    data.drawnTile.add(replacementTiles.removeLast()); // 嶺上牌を手牌に移動する。
    wallTiles.removeAt(0); // 山牌の牌を一つ消す。
    countOfKan += 1;

    state = TableState.waitToDiscardForCloseKan;
    _updateTableListener();
  }

  handleSetSelectedTilesForLateKan(
      {required String peerId, required int tile}) {
    _checkState(peerId, allowTableState: [
      TableState.selectingTilesForLateKan,
    ]);

    final data = playerData(peerId)!;

    var targetIndex = -1;
    for (var i = 0; i < data.calledTiles.length; i++) {
      if (data.calledTiles[i].canLateKanWith(tile)) {
        targetIndex = i;
      }
    }
    if (targetIndex < 0) throw ArgumentError("Bad selected tile.");

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

    state = TableState.waitToDiscardForLateKan;
    _updateTableListener();
  }

  void _setSelectedTiles(
      String peerId, List<int> selectedTiles, String callAs) {
    // 鳴き牌を持ち牌から除外
    final data = playerData(peerId)!;
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
}
