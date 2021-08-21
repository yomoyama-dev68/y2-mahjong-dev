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

class HandLocalState {
  bool onTradingScore = false;
  bool onCalledTsumo = false;
  bool onCalledRiichi = false;
  String lastTurnedPeerId = "";
  final selectingTiles = <int>[];

  clear() {
    onTradingScore = false;
    onCalledTsumo = false;
    onCalledRiichi = false;
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
  final handLocalState = HandLocalState();

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

  Map<String, Function> commandMap() {
    return <String, Function>{
      "drawTile": table.handleDrawTile,
      "discardTile": table.handleDiscardTile,
      "discardTileWithRiichi": table.handleDiscardTileWithRiichi,
      "callRon": table.handleRon,
      "callPong": table.handlePong,
      "callChow": table.handleChow,
      "callOpenKan": table.handleOpenKan,
      "callSelfKan": table.handleSelfKan,
      "callCloseKan": table.handleCloseKan,
      "callLateKan": table.handleLateKan,
      "cancelCall": table.handleCancelCall,
      "setSelectedTilesForPongOrChow":
          table.handleSetSelectedTilesForPongOrChow,
      "setSelectedTilesForOpenKan": table.handleSetSelectedTilesForOpenKan,
      "setSelectedTilesForCloseKan": table.handleSetSelectedTilesForCloseKan,
      "setSelectedTilesForLateKan": table.handleSetSelectedTilesForLateKan,
      "openMyWall": table.handleOpenTiles,
      "requestScore": table.handleRequestScore,
      "acceptRequestedScore": table.handleAcceptRequestedScore,
      "refuseRequestedScore": table.handleRefuseRequestedScore,
      "requestNextHand": table.handleRequestNextHand,
      "finishHand": table.handleFinishHand,
    };
  }

  Future<void> cancelCall() async {
    handLocalState.clear();
    _handleCommandResult(await _handleCmd("cancelCall", myPeerId));
  }

  Future<void> pong() async {
    _handleCommandResult(await _handleCmd("callPong", myPeerId));
  }

  Future<void> chow() async {
    _handleCommandResult(await _handleCmd("callChow", myPeerId));
  }

  Future<void> openKan() async {
    _handleCommandResult(await _handleCmd("callOpenKan", myPeerId));
  }

  Future<void> selfKan() async {
    _handleCommandResult(await _handleCmd("callSelfKan", myPeerId));
  }

  Future<void> closeKan() async {
    _handleCommandResult(await _handleCmd("callCloseKan", myPeerId));
  }

  Future<void> lateKan() async {
    _handleCommandResult(await _handleCmd("callLateKan", myPeerId));
  }

  Future<void> setSelectedTilesForPongOrChow(List<int> selectedTiles) async {
    _handleCommandResult(await _handleCmd(
        "setSelectedTilesForPongOrChow", myPeerId,
        args: {"selectedTiles": selectedTiles}));
  }

  Future<void> setSelectedTilesForOpenKan(List<int> selectedTiles) async {
    _handleCommandResult(await _handleCmd(
        "setSelectedTilesForOpenKan", myPeerId,
        args: {"selectedTiles": selectedTiles}));
  }

  Future<void> setSelectedTilesForCloseKan(List<int> selectedTiles) async {
    _handleCommandResult(await _handleCmd(
        "setSelectedTilesForCloseKan", myPeerId,
        args: {"selectedTiles": selectedTiles}));
  }

  Future<void> setSelectedTilesForLateKan(int tile) async {
    _handleCommandResult(await _handleCmd(
        "setSelectedTilesForLateKan", myPeerId,
        args: {"tile": tile}));
  }

  void setSelectedTiles() {
    final selectedTiles = [...handLocalState.selectingTiles];
    handLocalState.clear();

    if (table.state == TableState.selectingTilesForPong) {
      setSelectedTilesForPongOrChow(selectedTiles);
    }
    if (table.state == TableState.selectingTilesForChow) {
      setSelectedTilesForPongOrChow(selectedTiles);
    }
    if (table.state == TableState.selectingTilesForOpenKan) {
      setSelectedTilesForOpenKan(selectedTiles);
    }
    if (table.state == TableState.selectingTilesForCloseKan) {
      setSelectedTilesForCloseKan(selectedTiles);
    }
    if (table.state == TableState.selectingTilesForLateKan) {
      setSelectedTilesForLateKan(selectedTiles[0]);
    }
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
    _handleCommandResult(await _handleCmd("drawTile", myPeerId));
  }

  Future<void> discardTile(int tile) async {
    if (handLocalState.onCalledRiichi) {
      _handleCommandResult(
          await _handleCmd("discardTileWithRiichi", myPeerId, args: {"tile": tile}));
    } else {
      _handleCommandResult(
          await _handleCmd("discardTile", myPeerId, args: {"tile": tile}));

    }
  }

  Future<void> openMyWall() async {
    _handleCommandResult(await _handleCmd("openMyWall", myPeerId));
  }

  Future<void> ron() async {
    _handleCommandResult(await _handleCmd("ron", myPeerId));
  }

  Future<void> finishHand() async {
    _handleCommandResult(await _handleCmd("finishHand", myPeerId));
  }

  Future<void> riichi() async {
    handLocalState.onCalledRiichi = true;
    onChangedState();
  }

  Future<void> cancelRiichi() async {
    handLocalState.onCalledRiichi = false;
    onChangedState();
  }

  void tsumo() {
    handLocalState.onCalledTsumo = true;
    onChangedState();
  }

  void cancelTsumo() {
    handLocalState.onCalledTsumo = false;
    onChangedState();
  }

  void startTradingScore() {
    handLocalState.onTradingScore = true;
    onChangedState();
  }

  void cancelTradingScore() {
    handLocalState.onTradingScore = false;
    onChangedState();
  }

  Future<void> requestScore(Map<String, int> request) async {
    _handleCommandResult(
        await _handleCmd("requestScore", myPeerId, args: {"request": request}));
    handLocalState.onTradingScore = false;
    onChangedState();
  }

  Future<void> acceptRequestedScore() async {
    _handleCommandResult(await _handleCmd("acceptRequestedScore", myPeerId));
  }

  Future<void> refuseRequestedScore() async {
    _handleCommandResult(await _handleCmd("refuseRequestedScore", myPeerId));
  }

  Future<void> requestNextHand() async {
    handLocalState.clear();
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
    if (handLocalState.lastTurnedPeerId == myPeerId &&
        handLocalState.lastTurnedPeerId != table.turnedPeerId) {
      handLocalState.clear();
    }
    handLocalState.lastTurnedPeerId = table.turnedPeerId;

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
