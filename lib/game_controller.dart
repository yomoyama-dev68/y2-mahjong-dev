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

class Game {
  Game(this.roomId, this.onChangedState) {
    table = Table(_tableOnUpdateTable);
    skyWay.newPeer(skyWayKey, 3, (peerId) {
      print("newPeer ${peerId}");
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

  Future<void> drawTile() async {
    print("drawTile(): ${myPeerId}, ${_isOwner()}");
    if (_isOwner()) {
      final result = table.handleDrawTileCmd(myPeerId);
      _handleCommandResult(result);
    } else {
      _commandHandler
          .sendCommand(myPeerId, {"command": "drawTile"}).then((result) {
        print("drawTile(): result: ${result}");
        _handleCommandResult(result);
      });
    }
  }

  Future<void> discardTile(int tile) async {
    if (_isOwner()) {
      final result = table.handleDiscardTileCmd(myPeerId, tile);
      _handleCommandResult(result);
    } else {
      _commandHandler.sendCommand(myPeerId,
          {"command": "discardTile", "commandArgs:tile": tile}).then((result) {
        _handleCommandResult(result);
      });
    }
  }

  Future<void> openMyWall() async {
    if (_isOwner()) {
      final result = table.handleOpenTilesCmd(myPeerId);
      _handleCommandResult(result);
    } else {
      _commandHandler
          .sendCommand(myPeerId, {"command": "openMyWall"}).then((result) {
        _handleCommandResult(result);
      });
    }
  }

  Future<void> ron() async {
    if (_isOwner()) {
      final result = table.handleRonCmd(myPeerId);
      _handleCommandResult(result);
    } else {
      _commandHandler
          .sendCommand(myPeerId, {"command": "handleRonCmd"}).then((result) {
        _handleCommandResult(result);
      });
    }
  }

  Future<void> finishHand() async {
    if (_isOwner()) {
      final result = table.handleFinishHandCmd(myPeerId);
      _handleCommandResult(result);
    } else {
      _commandHandler
          .sendCommand(myPeerId, {"command": "handleFinishHandCmd"}).then((result) {
        _handleCommandResult(result);
      });
    }
  }

  bool isTradingScore = false;

  void startTradingScore() {
    isTradingScore = true;
    onChangedState();
  }

  void cancelTradingScore() {
    isTradingScore = false;
    onChangedState();
  }

  Future<void> requestScore(Map<String, int> request) async {
    print("requestTradingScore: ${request}");
    if (_isOwner()) {
      final result = table.handleRequestScore(myPeerId, request);
      _handleCommandResult(result);
    } else {
      _commandHandler.sendCommand(myPeerId, {
        "command": "requestScore",
        "commandArgs:request": request //Map<String, int> request
      }).then((result) {
        _handleCommandResult(result);
      });
    }
    isTradingScore = false;
    onChangedState();
  }

  Future<void> acceptRequestedScore() async {
    if (_isOwner()) {
      final result = table.handleAcceptRequestedScore(myPeerId);
      _handleCommandResult(result);
    } else {
      _commandHandler.sendCommand(myPeerId, {
        "command": "acceptRequestedScore",
      }).then((result) {
        _handleCommandResult(result);
      });
    }
  }

  Future<void> refuseRequestedScore() async {
    if (_isOwner()) {
      final result = table.handleRefuseRequestedScore(myPeerId);
      _handleCommandResult(result);
    } else {
      _commandHandler.sendCommand(myPeerId, {
        "command": "refuseRequestedScore",
      }).then((result) {
        _handleCommandResult(result);
      });
    }
  }

  Future<void> requestNextHand() async {
    if (_isOwner()) {
      final result = table.handleRequestNextHand(myPeerId);
      _handleCommandResult(result);
    } else {
      _commandHandler.sendCommand(myPeerId, {
        "command": "requestNextHand",
      }).then((result) {
        _handleCommandResult(result);
      });
    }
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
    print("_skyWayOnUpdateTable: ${myName()} ${tableData}");
    table.applyData(tableData);
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

  void _skyWayOnReceiveCommand(Map<String, dynamic> data) {
    if (!_isOwner()) return; // コマンドの処理はオーナのみが行う。

    final command = data["command"] as String;
    final commander = data["commander"] as String;

    if (command == "drawTile") {
      _commandHandler.sendCommandResult(
          data, table.handleDrawTileCmd(commander));
    }

    if (command == "discardTile") {
      final tile = data["commandArgs:tile"] as int;
      _commandHandler.sendCommandResult(
          data, table.handleDiscardTileCmd(commander, tile));
    }

    if (command == "openMyWall") {
      _commandHandler.sendCommandResult(
          data, table.handleOpenTilesCmd(commander));
    }

    if (command == "requestScore") {
      final request = (data["commandArgs:request"] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as int));
      print("requestScore: ${request}");
      _commandHandler.sendCommandResult(
          data, table.handleRequestScore(commander, request));
    }

    if (command == "acceptRequestedScore") {
      _commandHandler.sendCommandResult(
          data, table.handleAcceptRequestedScore(commander));
    }

    if (command == "refuseRequestedScore") {
      _commandHandler.sendCommandResult(
          data, table.handleRefuseRequestedScore(commander));
    }

    if (command == "requestNextHand") {
      _commandHandler.sendCommandResult(
          data, table.handleRequestNextHand(commander));
    }

    if (command == "handleRonCmd") {
      _commandHandler.sendCommandResult(
          data, table.handleRonCmd(commander));
    }

    if (command == "handleFinishHandCmd") {
      _commandHandler.sendCommandResult(
          data, table.handleFinishHandCmd(commander));
    }
  }

  void _handleCommandResult(CommandResult result) {
    print("_handleCommandResult: ${result.message}");
    onChangedState();
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

  void _tableOnUpdateTable() {
    final tmp = <String, dynamic>{
      "type": "updateTableData",
      "data": table.toMap(),
    };
    // print("_tableOnUpdateTable: ${myName()}: ${jsonEncode(tmp)}");

    skyWay.sendData(jsonEncode(tmp));
    onChangedState();
  }
}
