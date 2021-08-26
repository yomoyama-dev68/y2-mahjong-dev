import 'dart:async';
import 'dart:convert';

import 'table_controller.dart';
import 'skyway_wrapper.dart' as wrapper;
import 'commad_handler.dart';

const skyWayKey = '05bd41ee-71ec-4d8b-bd68-f6b7e1172b76';
const roomMode = "mesh";

enum State {
  onCreatingMyPeer,
  onJoiningRoom,
  onSettingMyName,
  onWaitingOtherPlayersForStart,
  onWaitingOtherPlayersInGame,
  onGame,
}

class MyTurnTempState {
  bool onCalledRiichi = false;
  bool onCalledRon = false;
  bool onCalledTsumo = false;
  bool onTradingScore = false;

  String onCalledFor = ""; //[pong, chow, open-kan, ]
  var selectedCalledTilesIndexForLateKan = -1;
  final selectingTiles = <int>[];

  clear() {
    onCalledRiichi = false;
    onCalledRon = false;
    onCalledTsumo = false;
    onTradingScore = false;
    onCalledFor = "";
    selectedCalledTilesIndexForLateKan = -1;
    selectingTiles.clear();
  }
}

class Game {
  Game(this.roomId, this.onChangedState) {
    table = Table(_tableOnUpdateTable);
    skyWay.newPeer(skyWayKey, 3, (peerId) {
      _commandHandler = CommandHandler(skyWay);
      myPeerId = peerId;
      state = State.onJoiningRoom;
      onChangedState();
      skyWay.joinRoom(
          roomId,
          roomMode,
          _skyWayOnOpen,
          _skyWayOnPeerJoin,
          _skyWayOnStreamCallback,
          _skyWayOnData,
          _skyWayOnPeerLeave,
          _skyWayOnClose);
    });
  }

  final skyWay = wrapper.SkyWayHelper(useStab: true);
  final roomId;
  final Function onChangedState;
  final member = <String, String>{};
  late String myPeerId;
  late Table table;
  late CommandHandler _commandHandler;
  String lastTurnedPeerId = "";
  final myTurnTempState = MyTurnTempState();

  State state = State.onCreatingMyPeer;

  String myName() {
    return member[myPeerId] ?? "";
  }

  void setMyName(String name) {
    print("setMyName: ${myPeerId}, ${name}");
    state = State.onWaitingOtherPlayersForStart;
    _onUpdateMemberMap(myPeerId, name);
    final tmp = <String, dynamic>{
      "type": "notifyMyName",
      "name": name,
    };
    skyWay.sendData(jsonEncode(tmp));
    onChangedState();
  }

  bool canCommand() {
    return _commandHandler.canCommand();
  }

  bool isMyTurn() {
    return myPeerId == table.turnedPeerId;
  }

  Map<String, Function> commandMap() {
    return <String, Function>{
      "handleDrawTile": table.handleDrawTile,
      "handleDiscardTile": table.handleDiscardTile,
      "handleDiscardTileWithRiichi": table.handleDiscardTileWithRiichi,
      "handleCall": table.handleCall,
      "handleCancelCall": table.handleCancelCall,
      "handleWin": table.handleWin,
      "handlePongOrChow": table.handlePongOrChow,
      "handleOpenKan": table.handleOpenKan,
      "handleCloseKan": table.handleCloseKan,
      "handleLateKan": table.handleLateKan,
      "openMyWall": table.handleOpenTiles,
      "requestScore": table.handleRequestScore,
      "acceptRequestedScore": table.handleAcceptRequestedScore,
      "refuseRequestedScore": table.handleRefuseRequestedScore,
      "requestNextHand": table.handleRequestNextHand,
    };
  }

  Future<CommandResult> _handleCmd(String commandName, String peerId,
      {Map<String, dynamic> args = const {}, viaNet = false}) async {
    // Ownerプレーヤーから直接呼ばれた場合は、公平さのため通信時間を考慮した待機時間を入れる。
    if (!viaNet) await Future.delayed(const Duration(microseconds: 50));

    print("_handleCmd: ${commandName}: ${args}");
    if (viaNet) print("viaNet: _handleCmd: ${commandName}: ${args}");
    if (_isOwner()) {
      final Function f = commandMap()[commandName]!;
      final namedArguments = <Symbol, dynamic>{const Symbol("peerId"): peerId};
      namedArguments
          .addAll(args.map((key, value) => MapEntry(Symbol(key), value)));
      try {
        Function.apply(f, [], namedArguments);
      } on StateError catch (e) {
        return CommandResult(CommandResultStateCode.error, e.message);
      } on NotYourTurnException catch (e) {
        return CommandResult(CommandResultStateCode.refuse, e.message);
      }
      return CommandResult(CommandResultStateCode.ok, "");
    }
    return _commandHandler.sendCommand(peerId, commandName, args);
  }

  void _handleCommandResult(CommandResult result) {
    print("_handleCommandResult: ${result.message}");
    onChangedState();
  }

  Future<void> drawTile() async {
    _handleCommandResult(await _handleCmd("handleDrawTile", myPeerId));
  }

  Future<void> discardTile(int tile) async {
    if (myTurnTempState.onCalledRiichi) {
      _handleCommandResult(await _handleCmd(
          "handleDiscardTileWithRiichi", myPeerId,
          args: {"tile": tile}));
    } else {
      _handleCommandResult(await _handleCmd("handleDiscardTile", myPeerId,
          args: {"tile": tile}));
    }
  }

  Future<void> call() async {
    myTurnTempState.clear();
    _handleCommandResult(await _handleCmd("handleCall", myPeerId));
  }

  Future<void> callRon() async {
    myTurnTempState.clear();
    myTurnTempState.onCalledRon = true;
    _handleCommandResult(await _handleCmd("handleCall", myPeerId));
  }

  Future<void> cancelCall() async {
    myTurnTempState.clear();
    _handleCommandResult(await _handleCmd("handleCancelCall", myPeerId));
  }

  Future<void> win() async {
    myTurnTempState.clear();
    _handleCommandResult(await _handleCmd("handleWin", myPeerId));
  }

  int selectableTilesQuantity() {
    final reason = myTurnTempState.onCalledFor;
    if (reason == "pongOrChow") return 2;
    if (reason == "openKan") return 3;
    if (reason == "closeKan") return 4;
    if (reason == "lateKanStep1") return 1;
    return 0;
  }

  void setSelectedTiles() async {
    final selectedTiles = [...myTurnTempState.selectingTiles];
    final calledFor = myTurnTempState.onCalledFor;
    if (calledFor == "pongOrChow") {
      _handleCommandResult(await _handleCmd("handlePongOrChow", myPeerId,
          args: {"selectedTiles": selectedTiles}));
      myTurnTempState.clear();
    }
    if (calledFor == "openKan") {
      _handleCommandResult(await _handleCmd("handleOpenKan", myPeerId,
          args: {"selectedTiles": selectedTiles}));
      myTurnTempState.clear();
    }
    if (calledFor == "lateKanStep1") {
      myTurnTempState.onCalledFor = "lateKanStep2";
      onChangedState();
    }
    if (calledFor == "lateKanStep2") {
      final calledTilesIndex =
          myTurnTempState.selectedCalledTilesIndexForLateKan;
      _handleCommandResult(await _handleCmd("handleLateKan", myPeerId, args: {
        "tile": selectedTiles[0],
        "calledTilesIndex": calledTilesIndex
      }));
      myTurnTempState.clear();
      onChangedState();
    }
  }

  void pong() {
    myTurnTempState.onCalledFor = "pongOrChow";
    onChangedState();
  }

  void chow() {
    myTurnTempState.onCalledFor = "pongOrChow";
    onChangedState();
  }

  void openKan() {
    myTurnTempState.onCalledFor = "openKan";
    onChangedState();
  }

  void closeKan() {
    myTurnTempState.onCalledFor = "closeKan";
    onChangedState();
  }

  void lateKan() {
    myTurnTempState.onCalledFor = "lateKanStep1";
    onChangedState();
  }

  Future<void> riichi() async {
    myTurnTempState.onCalledRiichi = true;
    onChangedState();
  }

  Future<void> cancelRiichi() async {
    myTurnTempState.onCalledRiichi = false;
    onChangedState();
  }

  void tsumo() {
    myTurnTempState.onCalledTsumo = true;
    onChangedState();
  }

  void cancelTsumo() {
    myTurnTempState.onCalledTsumo = false;
    onChangedState();
  }

  void startTradingScore() {
    myTurnTempState.onTradingScore = true;
    onChangedState();
  }

  void cancelTradingScore() {
    myTurnTempState.onTradingScore = false;
    onChangedState();
  }

  Future<void> openMyWall() async {
    _handleCommandResult(await _handleCmd("openMyWall", myPeerId));
  }

  Future<void> requestScore(Map<String, int> request) async {
    _handleCommandResult(
        await _handleCmd("requestScore", myPeerId, args: {"request": request}));
    myTurnTempState.onTradingScore = false;
    onChangedState();
  }

  Future<void> acceptRequestedScore() async {
    _handleCommandResult(await _handleCmd("acceptRequestedScore", myPeerId));
  }

  Future<void> refuseRequestedScore() async {
    _handleCommandResult(await _handleCmd("refuseRequestedScore", myPeerId));
  }

  Future<void> requestNextHand() async {
    myTurnTempState.clear();
    _handleCommandResult(await _handleCmd("requestNextHand", myPeerId));
  }

  void _skyWayOnOpen() {
    print("_skyWayOnOpen: $myPeerId");
    state = State.onSettingMyName;
    onChangedState();
  }

  void _skyWayOnPeerJoin(String peerId) {
    print("_skyWayOnPeerJoin: $peerId");
  }

  void _skyWayOnStreamCallback() {
    print("_skyWayOnStreamCallback:");
  }

  void _skyWayOnData(String data, String peerId) {
    _skyWayHandleReceivedData(data, peerId);
  }

  void _skyWayOnPeerLeave(String peerId) {
    print("_skyWayOnPeerLeave: $peerId");
    member.remove(peerId);
    state = State.onWaitingOtherPlayersInGame;
  }

  void _skyWayOnClose() {
    print("_skyWayOnClose:");
  }

  void _skyWayHandleReceivedData(String jsonStrData, String senderPeerId) {
    final data = jsonDecode(jsonStrData) as Map<String, dynamic>;
    final dataType = data["type"] as String;

    if (dataType == "notifyMyName") {
      final name = data["name"] as String;
      _onUpdateMemberMap(senderPeerId, name);
    }

    if (dataType == "command") {
      _skyWayOnReceiveCommand(data);
    }

    if (dataType == "commandResult") {
      _commandHandler.onReceiveCommandResult(data, myPeerId);
    }

    if (dataType == "updateTableData") {
      _skyWayOnUpdateTable(data["data"] as Map<String, dynamic>);
    }
  }

  void _skyWayOnUpdateTable(Map<String, dynamic> tableData) {
    // print("_skyWayOnUpdateTable: ${myName()} ${tableData}");
    table.applyData(tableData);
    // 自分のターンが終わったとき、自ターンのときの操作状態をクリアする。
    if (lastTurnedPeerId == myPeerId &&
        lastTurnedPeerId != table.turnedPeerId) {
      myTurnTempState.clear();
    }
    lastTurnedPeerId = table.turnedPeerId;

    onChangedState();
  }

  void _skyWayOnReceiveCommand(Map<String, dynamic> data) {
    if (!_isOwner()) return; // コマンドの処理はオーナのみが行う。

    final commander = data["commander"] as String;
    final commandName = data["commandName"] as String;
    final commandArgs = data["commandArgs"] as Map<String, dynamic>;

    print("_skyWayOnReceiveCommand: ${commandArgs}");
    _handleCmd(commandName, commander, args: commandArgs, viaNet: true)
        .then((result) => _commandHandler.sendCommandResult(data, result));
  }

  // caller:self or skyWay
  void _onUpdateMemberMap(String peerId, String name) {
    member[peerId] = name;
    print("_onUpdateMemberMap: ${myName()}: ${member.length}");
    if (member.length == 4) {
      if (state == State.onWaitingOtherPlayersForStart) {
        state = State.onGame;
        if (_isOwner()) {
          print("_onUpdateMemberMap: ${myName()} _isOwner. startGame");
          _startGame();
        }
      }
    }

    onChangedState();
  }

  bool _isOwner() {
    // ピアIDの並び順でゲームオーナーを決定する。
    final peers = member.keys.toList();
    peers.sort();
    return peers.first == myPeerId;
  }

  void _startGame() {
    table.startGame(member);
    table.nextLeader();
  }

  void _tableOnUpdateTable() {
    final tmp = <String, dynamic>{
      "type": "updateTableData",
      "data": table.toMap(),
    };
    skyWay.sendData(jsonEncode(tmp));
    onChangedState();
  }
}
