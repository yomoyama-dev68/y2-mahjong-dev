import 'dart:async';
import 'dart:convert';

import 'table_controller.dart';
import 'skyway_wrapper.dart' as wrapper;
import 'commad_handler.dart';

const skyWayKey = '05bd41ee-71ec-4d8b-bd68-f6b7e1172b76';
const roomMode = "mesh";
const useStab = false;

enum GameState {
  onCreatingMyPeer,
  onJoiningRoom,
  onSettingMyName,
  onNeedRejoin,
  onWaitingOtherPlayersForStart,
  onWaitingOtherPlayersInGame,
  onGame,
}

class MyTurnTempState {
  bool onCalledRiichi = false;
  bool onCalledRon = false;
  bool onCalledTsumo = false;

  String onCalledFor = ""; //[pong, chow, open-kan, ]
  var selectedCalledTilesIndexForLateKan = -1;
  final selectingTiles = <int>[];

  clear() {
    onCalledRiichi = false;
    onCalledRon = false;
    onCalledTsumo = false;
    onCalledFor = "";
    selectedCalledTilesIndexForLateKan = -1;
    selectingTiles.clear();
  }
}

class Game {
  Game(
      {required this.roomId,
      required this.onChangeGameState,
      required this.onChangeMember,
      required this.onChangeGameTableState,
      required this.onRequestScore,
      required this.onEventGameTable,
      required this.onChangeGameTableData,
      required this.onReceiveCommandResult,
      required this.onSetupLocalAudio}) {
    print("Game:Game():1");
    table = Table(_tableOnUpdateTable, _onAcceptRollback);
    print("Game:Game():2");
    oldTableData = table.toMap();
    print("Game:Game():3");
    skyWay.setupLocalAudio((enabled, message) {
      print("Game:Game():3-1");
      enabledAudio = enabled;
      availableAudio = enabled;
      onSetupLocalAudio(enabled, message);
      print("Game:Game():3-2");
      skyWay.newPeer(skyWayKey, 3, (peerId) {
        print("Game:Game():4: ${peerId}");
        _commandHandler = CommandHandler(skyWay);
        print("Game:Game():5");
        myPeerId = peerId;
        _setState(GameState.onJoiningRoom);
        print("Game:Game():6");
        skyWay.joinRoom(
            roomId,
            roomMode,
            _skyWayOnOpen,
            _skyWayOnPeerJoin,
            _skyWayOnStreamCallback,
            _skyWayOnData,
            _skyWayOnPeerLeave,
            _skyWayOnClose);
        print("Game:Game():7");
      });
    });
  }

  final skyWay = wrapper.SkyWayHelper(useStab: useStab);
  final roomId;
  final Function(GameState, GameState) onChangeGameState;
  final Function(List<String>, List<String>) onChangeMember;
  final Function(String, String) onChangeGameTableState;
  final Function(String, int) onRequestScore;
  final Function onEventGameTable;
  final Function(String) onChangeGameTableData;
  final Function(CommandResult) onReceiveCommandResult;
  final Function(bool, String) onSetupLocalAudio;

  final member = <String, String>{}; // <Peer ID, Player Name>
  final lostPlayerNames = <String, String>{}; // <Player Name, Peer ID>
  late String myPeerId;
  late Table table;
  late Map<String, dynamic> oldTableData;
  late CommandHandler _commandHandler;
  String lastTurnedPeerId = "";
  final myTurnTempState = MyTurnTempState();
  Function()? onChangeSelectingTiles;
  Function()? onChangeMyTurnTempState;
  bool isAudience = false;
  String audienceAs = "";
  var enabledAudio = false;
  var availableAudio = false;

  final tableDataLogs = <Map<String, dynamic>>[];

  GameState state = GameState.onCreatingMyPeer;

  void _setState(GameState newState) {
    if (state == newState) return;
    final oldState = state;
    state = newState;
    onChangeGameState(oldState, state);
  }

  setEnabledAudio(bool enabled) {
    if (availableAudio) {
      enabledAudio = enabled;
      skyWay.setEnabledAudio(enabled);
    }
  }

  String myName() {
    return member[myPeerId] ?? "";
  }

  void setMyName(String name) async {
    assert(isAudience == false);
    print("setMyName: ${myPeerId}, ${name}");
    _setState(GameState.onWaitingOtherPlayersForStart);
    final tmp = <String, dynamic>{
      "type": "notifyMyName",
      "name": name,
    };
    skyWay.sendData(jsonEncode(tmp));
    _onUpdateMemberMap(myPeerId, name);
  }

  void joinAsAudience() {
    isAudience = true;
    if (member.length < 4) {
      if (lostPlayerNames.isEmpty) {
        _setState(GameState.onWaitingOtherPlayersForStart);
      } else {
        _setState(GameState.onWaitingOtherPlayersInGame);
      }
    } else {
      _setState(GameState.onGame);
    }
  }

  void setAudienceAs(String peerId) {
    audienceAs = peerId;
    onEventGameTable("setAudienceAs:${peerId}");
  }

  void rejoinAs(String name) async {
    assert(isAudience == false);
    final oldPeerId = lostPlayerNames.remove(name)!;
    final tmp = <String, dynamic>{
      "type": "rejoinAs",
      "name": name,
      "oldPeerId": oldPeerId,
      "newPeerId": myPeerId,
    };
    skyWay.sendData(jsonEncode(tmp));

    final oldMember = member.values.toList();
    member[myPeerId] = name;
    final newMember = member.values.toList();
    onChangeMember(oldMember, newMember);
    if (member.length == 4) {
      _setState(GameState.onGame);
    } else {
      _setState(GameState.onWaitingOtherPlayersInGame);
    }
  }

  bool canCommand() {
    return _commandHandler.canCommand();
  }

  bool isMyTurn() {
    return myPeerId == table.turnedPeerId;
  }

  bool existRiichiBar() {
    if (table.remainRiichiBarCounts > 0) return true;
    for (final data in table.playerDataMap.values) {
      if (data.existRiichiBar) return true;
    }
    return false;
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
      "handleOpenTiles": table.handleOpenTiles,
      "handleRequestScore": table.handleRequestScore,
      "handleAcceptRequestedScore": table.handleAcceptRequestedScore,
      "handleRequestDrawGame": table.handleRequestDrawGame,
      "handleAcceptDrawGame": table.handleAcceptDrawGame,
      "handleRefuseDrawGame": table.handleRefuseDrawGame,
      "handleRequestNextHand": table.handleRequestNextHand,
      "handleAcceptNextHand": table.handleAcceptNextHand,
      "handleRefuseNextHand": table.handleRefuseNextHand,
      "handleRequestGameReset": table.handleRequestGameReset,
      "handleAcceptGameReset": table.handleAcceptGameReset,
      "handleRefuseGameReset": table.handleRefuseGameReset,
      "handleSetLeaderContinuousCount": table.handleSetLeaderContinuousCount,
      "handleReplacePeerId": table.handleReplacePeerId,
      "handleGetRiichiBarScoreAll": table.handleGetRiichiBarScoreAll,
      //"handleRequestGetRiichiBarScore": table.handleRequestGetRiichiBarScore,
      //"handleAcceptGetRiichiBarScore": table.handleAcceptGetRiichiBarScore,
      //"handleRefuseGetRiichiBarScore": table.handleRefuseGetRiichiBarScore,
      "handleRequestRollback": table.handleRequestRollback,
      "handleAcceptRollback": table.handleAcceptRollback,
      "handleRefuseRollback": table.handleRefuseRollback,
    };
  }

  Future<CommandResult> _handleCmd(String commandName, String peerId,
      {Map<String, dynamic> args = const {}, viaNet = false}) async {
    print("_handleCmd: ${commandName}: ${args}");
    if (viaNet) print("viaNet: _handleCmd: ${commandName}: ${args}");
    // Ownerプレーヤーから直接呼ばれた場合は、公平さのため通信時間を考慮した待機時間を入れる。
    if (!viaNet) await Future.delayed(const Duration(microseconds: 50));

    if (isOwner()) {
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
    print("_handleCommandResult: ${result}");
    onReceiveCommandResult(result);
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
    myTurnTempState.clear();
    onChangeMyTurnTempState?.call();
  }

  Future<void> call() async {
    _handleCommandResult(await _handleCmd("handleCall", myPeerId));
  }

  Future<void> callRon() async {
    myTurnTempState.onCalledRon = true;
    onChangeMyTurnTempState?.call();
    _handleCommandResult(await _handleCmd("handleCall", myPeerId));
  }

  Future<void> cancelCall() async {
    myTurnTempState.clear();
    onChangeMyTurnTempState?.call();
    _handleCommandResult(await _handleCmd("handleCancelCall", myPeerId));
  }

  Future<void> win() async {
    myTurnTempState.clear();
    onChangeMyTurnTempState?.call();
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
      onChangeMyTurnTempState?.call();
    }
    if (calledFor == "openKan") {
      _handleCommandResult(await _handleCmd("handleOpenKan", myPeerId,
          args: {"selectedTiles": selectedTiles}));
      myTurnTempState.clear();
      onChangeMyTurnTempState?.call();
    }
    if (calledFor == "closeKan") {
      _handleCommandResult(await _handleCmd("handleCloseKan", myPeerId,
          args: {"selectedTiles": selectedTiles}));
      myTurnTempState.clear();
      onChangeMyTurnTempState?.call();
    }

    if (calledFor == "lateKanStep1") {
      myTurnTempState.onCalledFor = "lateKanStep2";
      onChangeMyTurnTempState?.call();
      print("calledFor == lateKanStep1");
      onChangeGameTableData("lateKanStep2");
    }

    if (calledFor == "lateKanStep2") {
      final calledTilesIndex =
          myTurnTempState.selectedCalledTilesIndexForLateKan;
      _handleCommandResult(await _handleCmd("handleLateKan", myPeerId, args: {
        "tile": selectedTiles[0],
        "calledTilesIndex": calledTilesIndex
      }));
      myTurnTempState.clear();
      onChangeMyTurnTempState?.call();
    }
  }

  void pong() {
    myTurnTempState.onCalledFor = "pongOrChow";
    onChangeMyTurnTempState?.call();
  }

  void chow() {
    myTurnTempState.onCalledFor = "pongOrChow";
    onChangeMyTurnTempState?.call();
  }

  void openKan() {
    myTurnTempState.onCalledFor = "openKan";
    onChangeMyTurnTempState?.call();
  }

  void closeKan() {
    myTurnTempState.onCalledFor = "closeKan";
    onChangeMyTurnTempState?.call();
  }

  void lateKan() {
    myTurnTempState.onCalledFor = "lateKanStep1";
    onChangeMyTurnTempState?.call();
  }

  void riichi() async {
    myTurnTempState.onCalledRiichi = true;
    onChangeMyTurnTempState?.call();
  }

  void cancelRiichi() async {
    myTurnTempState.onCalledRiichi = false;
    onChangeMyTurnTempState?.call();
  }

  void tsumo() {
    myTurnTempState.onCalledTsumo = true;
    onChangeMyTurnTempState?.call();
  }

  void cancelTsumo() {
    myTurnTempState.onCalledTsumo = false;
    onChangeMyTurnTempState?.call();
  }

  Future<void> openMyWall() async {
    _handleCommandResult(await _handleCmd("handleOpenTiles", myPeerId));
  }

  Future<void> requestScore(Map<String, int> request) async {
    final tmp = <String, dynamic>{
      "type": "requestScore",
      "request": request,
    };
    skyWay.sendData(jsonEncode(tmp));
  }

  Future<void> acceptRequestedScore(String requester, int score) async {
    _handleCommandResult(await _handleCmd(
        "handleAcceptRequestedScore", myPeerId,
        args: {"requester": requester, "score": score}));
  }

  Future<void> requestDrawGame() async {
    _handleCommandResult(await _handleCmd("handleRequestDrawGame", myPeerId));
  }

  Future<void> acceptDrawGame() async {
    _handleCommandResult(await _handleCmd("handleAcceptDrawGame", myPeerId));
  }

  Future<void> refuseDrawGame() async {
    _handleCommandResult(await _handleCmd("handleRefuseDrawGame", myPeerId));
  }

  Future<void> requestNextHand(String mode) async {
    _handleCommandResult(await _handleCmd("handleRequestNextHand", myPeerId,
        args: {"mode": mode}));
  }

  Future<void> acceptNextHand() async {
    _handleCommandResult(await _handleCmd("handleAcceptNextHand", myPeerId));
  }

  Future<void> refuseNextHand() async {
    _handleCommandResult(await _handleCmd("handleRefuseNextHand", myPeerId));
  }

  Future<void> requestGameReset() async {
    _handleCommandResult(await _handleCmd("handleRequestGameReset", myPeerId));
  }

  Future<void> acceptGameReset() async {
    _handleCommandResult(await _handleCmd("handleAcceptGameReset", myPeerId));
  }

  Future<void> refuseGameReset() async {
    _handleCommandResult(await _handleCmd("handleRefuseGameReset", myPeerId));
  }

  Future<void> setLeaderContinuousCount(int count) async {
    _handleCommandResult(await _handleCmd(
        "handleSetLeaderContinuousCount", myPeerId,
        args: {"count": count}));
  }

  Future<void> handleGetRiichiBarScoreAll() async {
    _handleCommandResult(
        await _handleCmd("handleGetRiichiBarScoreAll", myPeerId));
  }

  Future<void> handleRequestRollback(int index) async {
    _handleCommandResult(await _handleCmd("handleRequestRollback", myPeerId,
        args: {"index": index}));
  }

  Future<void> handleAcceptRollback() async {
    _handleCommandResult(await _handleCmd("handleAcceptRollback", myPeerId));
  }

  Future<void> handleRefuseRollback() async {
    _handleCommandResult(await _handleCmd("handleRefuseRollback", myPeerId));
  }

  /*
  Future<void> handleRequestGetRiichiBarScore(
      List<String> targetPeerIds, int numberOfRemainRiichiBars) async {
    _handleCommandResult(
        await _handleCmd("handleRequestGetRiichiBarScore", myPeerId, args: {
      "targetPeerIds": targetPeerIds,
      "numberOfRemainRiichiBars": numberOfRemainRiichiBars
    }));
  }

  Future<void> handleAcceptGetRiichiBarScore() async {
    _handleCommandResult(
        await _handleCmd("handleAcceptGetRiichiBarScore", myPeerId));
  }

  Future<void> handleRefuseGetRiichiBarScore() async {
    _handleCommandResult(
        await _handleCmd("handleRefuseGetRiichiBarScore", myPeerId));
  }
   */

  void _skyWayOnOpen() {
    print("_skyWayOnOpen: $myPeerId");
    _setState(GameState.onSettingMyName);
  }

  void _skyWayOnPeerJoin(String peerId) {
    print("_skyWayOnPeerJoin1: $peerId");
    final tmp = <String, dynamic>{
      "type": "notifyMember",
      "member": member,
      "lostPlayerNames": lostPlayerNames,
    };
    print("_skyWayOnPeerJoin2: $tmp");
    skyWay.sendData(jsonEncode(tmp));
    print("_skyWayOnPeerJoi3:");
  }

  void _skyWayOnStreamCallback() {
    print("_skyWayOnStreamCallback:");
  }

  void _skyWayOnData(String data, String peerId) {
    _skyWayHandleReceivedData(data, peerId);
  }

  void _skyWayOnPeerLeave(String peerId) {
    print("_skyWayOnPeerLeave: $peerId");
    myTurnTempState.clear();
    onChangeMyTurnTempState?.call();
    final name = member.remove(peerId);
    lostPlayerNames[name!] = peerId;
    _setState(GameState.onWaitingOtherPlayersInGame);
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

    if (dataType == "notifyMember") {
      // メンバーマップを最新のものに置き換える、
      member.addAll((data["member"] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)));
      // 通信途絶したメンバーが自分だった場合、通信と
      final lostMember = (data["lostPlayerNames"] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String));
      print(
          "notifyMember: myPeerId=${myPeerId}, member=${member}, lostMember=${lostMember}");
      print(
          "notifyMember: lostMember.isNotEmpty=${lostMember.isNotEmpty}, !member.containsKey(myPeerId)=${!member.containsKey(myPeerId)}");
      if (isAudience == false) {
        if (lostMember.isNotEmpty && !member.containsKey(myPeerId)) {
          lostPlayerNames
            ..clear()
            ..addAll(lostMember);
          _setState(GameState.onNeedRejoin);
          print("notifyMember: lostPlayerNames=${lostPlayerNames}");
        }
      }
    }

    if (dataType == "rejoinAs") {
      assert(state == GameState.onWaitingOtherPlayersInGame);
      final name = data["name"] as String;
      final oldPeerId = data["oldPeerId"] as String;
      final newPeerId = data["newPeerId"] as String;
      if (isOwner()) {
        table.handleReplacePeerId(peerId: newPeerId, oldPeerId: oldPeerId);
      }
      lostPlayerNames.remove(name)!;
      final oldMember = member.values.toList();
      member[newPeerId] = name;
      final newMember = member.values.toList();
      onChangeMember(oldMember, newMember);
      if (member.length == 4) {
        _setState(GameState.onGame);
      }
    }

    if (dataType == "requestScore") {
      final request = data["request"] as Map<String, dynamic>;
      if (request.containsKey(myPeerId)) {
        onRequestScore(senderPeerId, request[myPeerId]);
      }
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

    if (dataType == "rollback") {
      final logs =
          (data["tableDataLogs"] as List).map((e) => e as Map<String, dynamic>);
      tableDataLogs.clear();
      tableDataLogs.addAll(logs);
      final lastData = tableDataLogs.removeLast();
      print("_skyWayHandleReceivedData: rollback: ${lastData}");
      _skyWayOnUpdateTable(lastData);
    }
  }

  void _notifyUpdatedTableData(
      Map<String, dynamic> oldData, Map<String, dynamic> newData) {
    print("_notifyUpdatedTableData: ${myPeerId}, ${newData["updatedFor"]}");
    tableDataLogs.add(newData);

    if (oldData["state"] != newData["state"]) {
      onChangeGameTableState(oldData["state"], newData["state"]);
    }

    if (oldData["turnedPeerId"] != newData["turnedPeerId"]) {
      if (newData["turnedPeerId"] == myPeerId) {
        onEventGameTable("onMyTurned");
      }
    }

    onChangeGameTableData(newData["updatedFor"]);
  }

  void _skyWayOnUpdateTable(Map<String, dynamic> newTableData) {
    print("_skyWayOnUpdateTable: ${myPeerId}");
    table.applyData(newTableData);
    _notifyUpdatedTableData(oldTableData, newTableData);
    oldTableData = newTableData;
  }

  void _skyWayOnReceiveCommand(Map<String, dynamic> data) {
    if (!isOwner()) return; // コマンドの処理はオーナのみが行う。

    final commander = data["commander"] as String;
    final commandName = data["commandName"] as String;
    final commandArgs = data["commandArgs"] as Map<String, dynamic>;

    print("_skyWayOnReceiveCommand: ${commandArgs}");
    _handleCmd(commandName, commander, args: commandArgs, viaNet: true)
        .then((result) => _commandHandler.sendCommandResult(data, result));
  }

  // caller:self or skyWay
  void _onUpdateMemberMap(String peerId, String name) {
    if (member.length == 4) {
      print("_onUpdateMemberMap: Member is fully.");
      return;
    }

    final oldMember = member.values.toList();
    member[peerId] = name;
    final newMember = member.values.toList();
    onChangeMember(oldMember, newMember);

    print("_onUpdateMemberMap: ${myName()}: ${member.length}");
    if (member.length == 4) {
      if (state == GameState.onWaitingOtherPlayersForStart) {
        _setState(GameState.onGame);
        if (isOwner()) {
          print("_onUpdateMemberMap: ${myName()} _isOwner. startGame");
          _startGame();
        }
      }
    }
  }

  void _onAcceptRollback(int index) {
    assert(isOwner());
    for (final data in tableDataLogs) {
      print("_onAcceptRollback: ${data["updatedFor"]}");
    }
    tableDataLogs.removeRange(index + 1, tableDataLogs.length);
    for (final data in tableDataLogs) {
      print("_onAcceptRollback: ${data["updatedFor"]}");
    }

    final tmp = <String, dynamic>{
      "type": "rollback",
      "tableDataLogs": tableDataLogs,
    };
    skyWay.sendData(jsonEncode(tmp));

    final lastData = tableDataLogs.removeLast();
    table.applyData(lastData);
    _notifyUpdatedTableData(oldTableData, lastData);
    oldTableData = lastData;
  }

  bool isOwner() {
    // ピアIDの並び順でゲームオーナーを決定する。
    final peers = member.keys.toList();
    peers.sort();
    return peers.first == myPeerId;
  }

  void _startGame() {
    table.startGame(member);
    table.nextLeader();
  }

  // Called from TableController.
  void _tableOnUpdateTable(String updatedFor) {
    final newTableData = table.toMap();
    newTableData["updatedFor"] = updatedFor;

    final tmp = <String, dynamic>{
      "type": "updateTableData",
      "data": newTableData,
    };
    skyWay.sendData(jsonEncode(tmp));

    _notifyUpdatedTableData(oldTableData, newTableData);
    oldTableData = newTableData;
  }
}
