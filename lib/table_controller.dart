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

  @override
  String toString() {
    return "${type}-${number}";
  }
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
}

class PlayerData {
  PlayerData(this.name);

  factory PlayerData.fromJsonMap(Map<String, dynamic> map) {
    final data = PlayerData(map["name"]);

    data.requestingScoreFrom.addAll(
        (map["requestingScoreFrom"] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value as int)));

    data.acceptedDrawGame = map["acceptedDrawGame"] as bool;
    data.acceptedNextHand = map["acceptedNextHand"] as bool;
    data.acceptedGameReset = map["acceptedGameReset"] as bool;
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
  bool acceptedDrawGame = false;
  bool acceptedNextHand = false;
  bool acceptedGameReset = false;
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

    requestingScoreFrom.clear();
    acceptedDrawGame = false;
    acceptedNextHand = false;
    acceptedGameReset = false;
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map["name"] = name;
    map["score"] = score;
    map["requestingScoreFrom"] = requestingScoreFrom;
    map["acceptedDrawGame"] = acceptedDrawGame;
    map["acceptedNextHand"] = acceptedNextHand;
    map["acceptedGameReset"] = acceptedGameReset;
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
  // static const doneSetupHand = "doneSetupHand";

  static const drawable = "drawable";
  static const waitToDiscard = "waitToDiscard";
  static const waitToDiscardForOpenOrLateKan = "waitToDiscardForOpenOrLateKan";
  static const waitToDiscardForPongOrChow = "waitToDiscardForPongOrChow";
  static const called = "called";

  // nextLeader, previousLeader, continueLeader
  static const waitingDrawGame = "waitingDrawGame";
  static const drawGame = "drawGame";
  static const processingFinishHand = "processingFinishHand";
  static const waitingNextHandForNextLeader = "waitingNextHandForNextLeader";
  static const waitingNextHandForPreviousLeader =
      "waitingNextHandForPreviousLeader";
  static const waitingNextHandForContinueLeader =
      "waitingNextHandForContinueLeader";
  static const waitingGameReset = "waitingGameReset";
}

class TableData {
  // 荘中関連
  Map<String, PlayerData> playerDataMap = {}; // 親順ソート済み
  Map<String, String> oldPeerIdMap = {}; // <OldPeerId, NewPeerId>
  int leaderChangeCount = -1; // 局数: 0~3:東場, 4~7:南場,
  int leaderContinuousCount = 0; // 場数（親継続数）
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
    map["oldPeerIdMap"] = oldPeerIdMap;

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
    oldPeerIdMap = (map["oldPeerIdMap"] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value as String));
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
    final from2 = toCurrentPeerId(from);
    final to2 = toCurrentPeerId(to);
    print("direction: from: ${from}->${from2}, to: ${to}->${to2},");
    final index0 = idList().indexOf(from2);
    int index1 = idList().indexOf(to2);
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

  String toCurrentPeerId(String oldPeerId) {
    String currentPeerId = oldPeerId;
    while (true) {
      final tmp = oldPeerIdMap[currentPeerId];
      if (tmp == null) break;
      currentPeerId = tmp;
    }
    return currentPeerId;
  }

  PlayerData? playerData(String peerId) {
    return playerDataMap[peerId];
  }
}

class Table extends TableData {
  Table(this._updateTableListener);

  final Function() _updateTableListener;

  void startGame(Map<String, String> member) {
    leaderChangeCount = -1; // 局数: 0~3:東場, 4~7:南場,
    leaderContinuousCount = 0; // 場数（親継続数）
    remainRiichiBarCounts = 0; // リーチ供託棒数
    playerDataMap.clear();

    // メンバーの順番を乱数でシャッフルする。
    final shuffled = <String, String>{}; // <Peer ID, Player Name>
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
    _setupHand();
  }

  void setLeaderContinuousCount(int count) {
    leaderContinuousCount = count;
    _updateTableListener();
  }

  void handleReplacePeerId(
      {required String peerId, required String oldPeerId}) {
    oldPeerIdMap[oldPeerId] = peerId;

    // 荘中関連
    print("handleReplacePeerId: playerDataMap: ${playerDataMap},"
        "peerId=${peerId}, oldPeerId=${oldPeerId}");
    final newMap = playerDataMap.map((curPeerId, data) {
      return MapEntry(curPeerId == oldPeerId ? peerId : curPeerId, data);
    });
    playerDataMap
      ..clear()
      ..addAll(newMap);
    print("handleReplacePeerId: playerDataMap: ${playerDataMap}");
    // 局中関連
    turnedPeerId = turnedPeerId == oldPeerId ? peerId : turnedPeerId;
    lastDiscardedPlayerPeerID = lastDiscardedPlayerPeerID == oldPeerId
        ? peerId
        : lastDiscardedPlayerPeerID;
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
    state = TableState.doingSetupHand;

    lastDiscardedTile = -1;
    lastDiscardedPlayerPeerID = "";
    countOfKan = 0;

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

    state = TableState.processingFinishHand;
    _updateTableListener();
  }

  _checkState(String peerId,
      {bool needMyTurn = false,
      bool needNotMyTurn = false,
      List<String> allowTableState = const []}) {
    final data = playerData(peerId);
    if (data == null) {
      throw StateError("No Player(${peerId}) data.");
    }
    if (needMyTurn && turnedPeerId != peerId) {
      throw StateError("Not your(${peerId}) turn.");
    }
    if (needNotMyTurn && turnedPeerId == peerId) {
      throw StateError("Already your(${peerId}) turn.");
    }
    if (allowTableState.isNotEmpty && !allowTableState.contains(state)) {
      throw StateError("Not allowed state(${state}).");
    }
  }

  handleDrawTile({required String peerId}) {
    if (turnedPeerId != peerId) throw NotYourTurnException();

    _checkState(peerId,
        needMyTurn: true, allowTableState: [TableState.drawable]);

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
    _checkState(peerId, needMyTurn: true, allowTableState: [
      TableState.waitToDiscard,
      TableState.waitToDiscardForPongOrChow,
      TableState.waitToDiscardForOpenOrLateKan
    ]);

    final data = playerData(peerId)!;

    var expectedDrawnTileQuantity = 0;
    if ([TableState.waitToDiscard, TableState.waitToDiscardForOpenOrLateKan]
        .contains(state)) {
      expectedDrawnTileQuantity = 1;
    }

    if (data.drawnTile.length != expectedDrawnTileQuantity) {
      throw StateError("Quantity of drawn tile is unexpected."
          " (State:${state}, Quantity: ${data.drawnTile.length})");
    }
    data.tiles.addAll(data.drawnTile);
    data.drawnTile.clear();
    if (!data.tiles.contains(tile)) {
      throw StateError("A discarded tile does not exist in my wall."
          " (tile: ${TileInfo(tile)})");
    }

    data.tiles.remove(tile);
    data.tiles.sort();
    data.discardedTiles.add(tile);

    lastDiscardedTile = tile;
    lastDiscardedPlayerPeerID = turnedPeerId;

    // 明槓の場合は 打牌後にドラをめくる。
    if (state == TableState.waitToDiscardForOpenOrLateKan) {
      countOfKan += 1;
    }

    _nextTurn(turnedPeerId);
    state = TableState.drawable;
    _updateTableListener();
  }

  handleDiscardTileWithRiichi({required String peerId, required int tile}) {
    _checkState(peerId,
        needMyTurn: true, allowTableState: [TableState.waitToDiscard]);
    final data = playerData(peerId)!;
    data.riichiTile.add(tile);
    handleDiscardTile(peerId: peerId, tile: tile);
  }

  handleCall({required String peerId}) {
    if (state != TableState.drawable) {
      throw RefuseException("Not callable state.");
    }
    _checkState(peerId, allowTableState: [TableState.drawable]);
    _turnTo(peerId);
    state = TableState.called;
    _updateTableListener();
  }

  handleCancelCall({required String peerId}) {
    _checkState(peerId, needMyTurn: true, allowTableState: [TableState.called]);
    _nextTurn(lastDiscardedPlayerPeerID);
    state = TableState.drawable;
    _updateTableListener();
  }

  handleWin({required String peerId}) {
    _checkState(peerId, needMyTurn: true, allowTableState: [
      TableState.waitToDiscard,
      TableState.waitToDiscardForOpenOrLateKan,
      TableState.called
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

    state = TableState.processingFinishHand;
    _updateTableListener();
  }

  handlePongOrChow(
      {required String peerId, required List<dynamic> selectedTiles}) {
    _checkState(peerId, needMyTurn: true, allowTableState: [TableState.called]);

    if (selectedTiles.length != 2) {
      throw ArgumentError("bad selected tiles quantity.");
    }

    _setSelectedTiles(peerId, _toListInt(selectedTiles), "pong-chow");

    state = TableState.waitToDiscardForPongOrChow;
    _updateTableListener();
  }

  handleOpenKan(
      {required String peerId, required List<dynamic> selectedTiles}) {
    if (countOfKan >= 4) {
      throw RefuseException("Already kan has been called 4 times.");
    }

    _checkState(peerId, needMyTurn: true, allowTableState: [TableState.called]);
    if (selectedTiles.length != 3) {
      throw ArgumentError("bad selected tiles quantity.");
    }

    _setSelectedTiles(peerId, _toListInt(selectedTiles), "open-kan");

    final data = playerData(peerId)!;
    data.drawnTile.add(replacementTiles.removeLast()); // 嶺上牌を手牌に移動する。
    wallTiles.removeAt(0); // 山牌の牌を一つ消す。

    state = TableState.waitToDiscardForOpenOrLateKan;
    _updateTableListener();
  }

  handleCloseKan(
      {required String peerId, required List<dynamic> selectedTiles}) {
    if (countOfKan >= 4) {
      throw RefuseException("Already kan has been called 4 times.");
    }

    _checkState(peerId,
        needMyTurn: true, allowTableState: [TableState.waitToDiscard]);

    if (selectedTiles.length != 4) {
      throw ArgumentError("bad selected tiles quantity.");
    }

    final data = playerData(peerId)!;
    // 鳴き牌登録
    data.calledTiles
        .add(CalledTiles(-1, peerId, _toListInt(selectedTiles), "close-kan"));
    // 鳴き牌を持ち牌から除外

    // 鳴き牌を持ち牌から除外
    data.tiles.addAll(data.drawnTile);
    data.drawnTile.clear();
    for (final tile in selectedTiles) {
      assert(data.tiles.remove(tile));
    }

    data.drawnTile.add(replacementTiles.removeLast()); // 嶺上牌を手牌に移動する。
    wallTiles.removeAt(0); // 山牌の牌を一つ消す。
    countOfKan += 1;

    state = TableState.waitToDiscard;
    _updateTableListener();
  }

  handleLateKan(
      {required String peerId,
      required int tile,
      required int calledTilesIndex}) {
    if (countOfKan >= 4) {
      throw RefuseException("Already kan has been called 4 times.");
    }

    _checkState(peerId,
        needMyTurn: true, allowTableState: [TableState.waitToDiscard]);

    final data = playerData(peerId)!;

    // ポンした刻子を小明槓にして入れ直す。
    final pongTiles = data.calledTiles[calledTilesIndex];
    if (pongTiles.selectedTiles.length > 2) {
      throw RefuseException("Late kan can do to only pong tiles.");
    }
    final selectedTiles = <int>[...pongTiles.selectedTiles, tile];
    final lateKanTiles = CalledTiles(
        pongTiles.calledTile, pongTiles.calledFrom, selectedTiles, "late-kan");
    data.calledTiles[calledTilesIndex] = lateKanTiles;
    // 鳴き牌を持ち牌から除外
    data.tiles
      ..addAll(data.drawnTile)
      ..remove(tile);
    data.drawnTile.clear();

    data.drawnTile.add(replacementTiles.removeLast()); // 嶺上牌を手牌に移動する。
    wallTiles.removeAt(0); // 山牌の牌を一つ消す。

    state = TableState.waitToDiscardForOpenOrLateKan;
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

  handleOpenTiles({required String peerId}) {
    _checkState(peerId);
    final data = playerData(peerId)!;
    data.openTiles = !data.openTiles;
    _updateTableListener();
  }

  handleRequestScore(
      {required String peerId, required Map<String, dynamic> request}) {
    for (final e in request.entries) {
      final data = playerData(e.key)!;
      data.requestingScoreFrom[peerId] = e.value; // Score
    }
    _updateTableListener();
  }

  handleAcceptRequestedScore(
      {required String peerId, required String requester, required int score}) {
    _checkState(peerId);
    final data1 = playerData(peerId)!;
    final data2 = playerData(requester)!;
    data1.score += score;
    data2.score -= score;
    _updateTableListener();
  }

  handleRequestNextHand({required String peerId, required String mode}) {
    _checkState(peerId,
        needMyTurn: false, allowTableState: [TableState.processingFinishHand]);

    for (final data in playerDataMap.values) {
      data.acceptedNextHand = false;
    }
    if (mode == "nextLeader") {
      state = TableState.waitingNextHandForNextLeader;
    }
    if (mode == "continueLeader") {
      state = TableState.waitingNextHandForContinueLeader;
    }
    if (mode == "previousLeader") {
      state = TableState.waitingNextHandForPreviousLeader;
    }
    _updateTableListener();
  }

  handleAcceptNextHand({required String peerId}) {
    _checkState(peerId, needMyTurn: false, allowTableState: [
      TableState.waitingNextHandForNextLeader,
      TableState.waitingNextHandForContinueLeader,
      TableState.waitingNextHandForPreviousLeader
    ]);

    final data = playerData(peerId)!;
    data.acceptedNextHand = true;

    var waitingNextHandCount = 0;
    for (final v in playerDataMap.values) {
      waitingNextHandCount += v.acceptedNextHand ? 1 : 0;
    }
    if (waitingNextHandCount == 4) {
      if (state == TableState.waitingNextHandForNextLeader) {
        nextLeader();
      }
      if (state == TableState.waitingNextHandForContinueLeader) {
        continueLeader();
      }
      if (state == TableState.waitingNextHandForPreviousLeader) {
        previousLeader();
      }
    }
  }

  handleRefuseNextHand({required String peerId}) {
    _checkState(peerId, needMyTurn: false, allowTableState: [
      TableState.waitingNextHandForNextLeader,
      TableState.waitingNextHandForContinueLeader,
      TableState.waitingNextHandForPreviousLeader
    ]);

    for (final data in playerDataMap.values) {
      data.acceptedNextHand = false;
    }
    state = TableState.processingFinishHand;
    _updateTableListener();
  }

  handleRequestDrawGame({required String peerId}) {
    _checkState(peerId,
        needMyTurn: false, allowTableState: [TableState.drawable]);
    for (final data in playerDataMap.values) {
      data.acceptedDrawGame = false;
    }
    state = TableState.waitingDrawGame;
    _updateTableListener();
  }

  handleAcceptDrawGame({required String peerId}) {
    _checkState(peerId,
        needMyTurn: false, allowTableState: [TableState.waitingDrawGame]);

    final data = playerData(peerId)!;
    data.acceptedDrawGame = true;

    var waitingPlayerCount = 0;
    for (final v in playerDataMap.values) {
      waitingPlayerCount += v.acceptedDrawGame ? 1 : 0;
    }
    if (waitingPlayerCount == 4) _onDrawGame();
  }

  handleRefuseDrawGame({required String peerId}) {
    _checkState(peerId,
        needMyTurn: false, allowTableState: [TableState.waitingDrawGame]);
    for (final data in playerDataMap.values) {
      data.acceptedDrawGame = false;
    }
    state = TableState.drawable;
    _updateTableListener();
  }

  handleRequestGameReset({required String peerId}) {
    _checkState(peerId,
        needMyTurn: false, allowTableState: [TableState.processingFinishHand]);
    for (final data in playerDataMap.values) {
      data.acceptedGameReset = false;
    }
    state = TableState.waitingGameReset;
    _updateTableListener();
  }

  handleAcceptGameReset({required String peerId}) {
    _checkState(peerId,
        needMyTurn: false, allowTableState: [TableState.waitingGameReset]);

    print("handleAcceptGameReset ${peerId}");
    final data = playerData(peerId)!;
    data.acceptedGameReset = true;

    var waitingPlayerCount = 0;
    for (final v in playerDataMap.values) {
      waitingPlayerCount += v.acceptedGameReset ? 1 : 0;
    }
    print("handleAcceptGameReset: waitingPlayerCount=${waitingPlayerCount}");
    if (waitingPlayerCount == 4) {
      final member =
          playerDataMap.map((key, value) => MapEntry(key, value.name));
      print("handleAcceptGameReset: member=${member}");
      startGame(member);
      nextLeader();
    }
  }

  handleRefuseGameReset({required String peerId}) {
    _checkState(peerId,
        needMyTurn: false, allowTableState: [TableState.waitingGameReset]);
    for (final data in playerDataMap.values) {
      data.acceptedGameReset = false;
    }
    state = TableState.processingFinishHand;
    _updateTableListener();
  }

  handleSetLeaderContinuousCount({required String peerId, required int count}) {
    setLeaderContinuousCount(count);
  }
}
