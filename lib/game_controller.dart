import 'dart:async';
import 'dart:convert';

import 'table_controller.dart';
import 'wrapper.dart' as wrapper;
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
    wrapper.newPeer(skyWayKey, 3, (peerId) {
      print("newPeer ${peerId}");
      myPeerId = peerId;
      state = State.onSettingMyName;
      onChangedState();
      wrapper.joinRoom(
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

  final roomId;
  final Function onChangedState;
  final member = <String, String>{};
  late String myPeerId;
  late Table table;
  final _commandHandler = CommandHandler();

  State state = State.onCreatingMyPeer;

  String myName() {
    return member[myPeerId] ?? "";
  }

  void setMyName(String name) {
    _onUpdateMemberMap(myPeerId, name);
    final tmp = <String, dynamic>{
      "type": "notifyMyName",
      "name": name,
    };
    wrapper.sendData(jsonEncode(tmp));
    state = State.onWaitingOtherPlayersForStart;
    onChangedState();
  }

  Future<void> drawTile() async {
    if (_isOwner()) {
      final result = table.handleDrawTileCmd(myPeerId);
      _handleCommandResult(result);
    } else {
      _commandHandler
          .sendCommand(myPeerId, {"command": "drawTile"}).then((result) {
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

  void _skyWayOnOpen() {
    state = State.onSettingMyName;
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
    onChangedState();
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
  }

  void _handleCommandResult(CommandResult result) {
    onChangedState();
  }

  // caller:self or skyWay
  void _onUpdateMemberMap(String peerId, String name) {
    member[peerId] = name;
    if (member.length == 4) {
      if (state == State.onWaitingOtherPlayersForStart) {
        state = State.onGame;
        if (_isOwner()) _startGame();
      }
    }
    onChangedState();
  }

  void _tableOnUpdateTable() {
    onChangedState();

    final tmp = <String, dynamic>{
      "type": "updateTableData",
      "data": table.toMap(),
    };
    wrapper.sendData(jsonEncode(tmp));
  }
}
