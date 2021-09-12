import 'package:flutter/material.dart';
import 'package:web_app_sample/dialogs/get_riichi_bar_score_dialog.dart';
import 'package:web_app_sample/widgets/player_state_tile.dart';
import 'package:web_app_sample/resources/sound_loader.dart';
import 'package:web_app_sample/widgets/stage_info_widget.dart';
import 'package:web_app_sample/resources/image_loader.dart';
import 'package:web_app_sample/widgets/trading_score_widget.dart';
import 'dart:ui' as ui;

import 'called_tiles_widget.dart';
import '../commad_handler.dart';
import '../game_controller.dart' as game;
import '../dialogs/name_set_dialog.dart';
import '../dialogs/next_hand_dialog.dart';
import '../table_controller.dart' as tbl;
import 'tiles_painter.dart';
import 'table_ribbon_widget.dart';
import 'mywall_widget.dart';
import 'dart:math';
import 'dart:html';

const baseTableSize = 700;
const tappableTileScale = 0.8;

class GameTableWidget extends StatefulWidget {
  const GameTableWidget({Key? key, required this.roomId, this.playerName})
      : super(key: key);

  final String roomId;
  final String? playerName;

  @override
  _GameTableWidgetState createState() => _GameTableWidgetState();
}

class _GameTableWidgetState extends State<GameTableWidget> {
  final Map<String, ui.Image> _uiImageMap = {};
  final Map<String, Image> _imageMap = {};
  late game.Game _game;
  bool showStageAndPlayerInfo = true;

  @override
  void initState() {
    print("_GameTableWidgetState:initState");
    super.initState();
    loadImages(tappableTileScale)
        .then((value) => onTileImageLoaded(value.uiImageMap, value.imageMap));
    _game = game.Game(
        roomId: widget.roomId,
        onChangeGameState: onChangeGameState,
        onChangeMember: onChangeMember,
        onChangeGameTableState: onChangeGameTableState,
        onChangeGameTableData: onChangeGameTableData,
        onRequestScore: onRequestScore,
        onEventGameTable: onEventGameTable,
        onReceiveCommandResult: onReceiveCommandResult);
  }

  void onChangeGameState(game.GameState oldState, game.GameState newState) {
    print("onChangeGameState: ${_game.myPeerId}: $oldState, $newState");
    if (newState == game.GameState.onSettingMyName) {
      _setMyName();
    }
    if (newState == game.GameState.onNeedRejoin) {
      _rejoin();
    }

    setState(() {});
  }

  void onChangeMember(List<String> oldMember, List<String> newMember) {
    setState(() {});
  }

  void onChangeGameTableState(String oldState, String newState) {
    print("onChangeGameTableState: ${_game.myPeerId}: $oldState, $newState");
    if (newState == tbl.TableState.waitingNextHandForNextLeader) {
      showAcceptNextHandDialog(context, _game, "親を流して次の局を始めます。");
    }
    if (newState == tbl.TableState.waitingNextHandForContinueLeader) {
      showAcceptNextHandDialog(context, _game, "連荘で次の局を始めます。");
    }
    if (newState == tbl.TableState.waitingNextHandForPreviousLeader) {
      showAcceptNextHandDialog(context, _game, "一局戻します。");
    }
    if (newState == tbl.TableState.waitingDrawGame) {
      showAcceptDrawGameDialog(context, _game);
    }
    if (newState == tbl.TableState.waitingGameReset) {
      showAcceptGameResetDialog(context, _game);
    }
    if (newState == tbl.TableState.processingFinishHand) {
      if (_game.table.lastWinner == _game.myPeerId && _game.existRiichiBar()) {
        showGetRiichiBarScoreDialogAll(context, _game);
      }
    }

    const waitToDiscards = [
      tbl.TableState.waitToDiscard,
      tbl.TableState.waitToDiscardForPongOrChow,
      tbl.TableState.waitToDiscardForOpenOrLateKan
    ];
  }

  void onChangeGameTableData(String updatedFor) {
    print("onChangeGameTableData");
    if (_game.isOwner()) {
      final soundMap = <String, Function>{
        "_setupHand2": Sounds.drawTile,
        "_setupHand3": Sounds.sortTiles,
        "handleDrawTile": Sounds.drawTile,
        "handleDiscardTile": Sounds.discardTile,
        "handlePongOrChow": Sounds.sortTiles,
        "handleOpenKan": Sounds.sortTiles,
        "handleCloseKan": Sounds.sortTiles,
        "handleLateKan": Sounds.sortTiles,
        "handleOpenTiles": Sounds.openMyWall,
        "handleWin": Sounds.call,
        "handleRequestNextHand": Sounds.call,
        "handleCall": Sounds.call,
        "handleCancelCall": Sounds.call,
        "handleRequestDrawGame": Sounds.call,
      };
      soundMap[updatedFor]?.call();
    }
    setState(() {});
  }

  void onRequestScore(String requester, int score) {
    showTradingScoreAcceptDialog(context, _game, requester, score);
  }

  void onEventGameTable(String event) {
    if (event == "onMyTurned") {}
  }

  void onReceiveCommandResult(CommandResult result) {
    setState(() {});
  }

  Future<void> _setMyName() async {
    if (widget.playerName != null) {
      _game.setMyName(widget.playerName!);
      return;
    }
    while (true) {
      final name = await NameSetDialog.show(context, _game.myName());
      print("NameSetDialog: ${name}");
      if (name != null) {
        _game.setMyName(name);
        return;
      }
      if (name == "close") return;
    }
  }

  Future<void> _rejoin() async {
    NameSetDialog.close();
    while (true) {
      final name = await RejoinNameSelectDialog.show(
          context, _game.lostPlayerNames.keys.toList());
      if (name != null) {
        _game.rejoinAs(name);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageMap.isEmpty) {
      return buildWaitingView("Loading images.");
    }
    if (_game.state == game.GameState.onCreatingMyPeer) {
      return buildWaitingView("Creating my peer.");
    }
    if (_game.state == game.GameState.onJoiningRoom) {
      return buildWaitingView("Creating a game room.");
    }
    if (_game.state == game.GameState.onSettingMyName) {
      return buildWaitingView("Setting my player name.");
    }
    if (_game.state == game.GameState.onWaitingOtherPlayersForStart) {
      return buildWaitingView("Waiting other players.");
    }
    if (_game.state == game.GameState.onWaitingOtherPlayersInGame) {
      final subtext = _game.lostPlayerNames.keys.toList().join(" と ");
      return buildWaitingView("${subtext}の接続が切れました。再接続を待っています。");
    }
    if (_game.table.playerDataMap.length != 4) {
      return buildWaitingView("Waiting data creation.");
    }
    if (window.innerWidth == null) {
      return buildWaitingView("Waiting data creation.");
    } else {
      final width = window.innerWidth!;
      final scale = width > baseTableSize ? 1.0 : width / baseTableSize;
      return buildBody(scale);
    }
  }

  Widget buildWaitingView(String message) {
    final widgets = <Widget>[Text(message), const CircularProgressIndicator()];
    for (final i in _game.member.entries) {
      widgets.add(Text("${i.key} - ${i.value}"));
    }
    return Column(children: widgets);
  }

  Widget buildBody(double scale) {
    final tableSize = baseTableSize * scale;

    final stacks = <Widget>[];
    stacks.add(GestureDetector(
        onTap: () {
          setState(() {
            showStageAndPlayerInfo = !showStageAndPlayerInfo;
          });
        },
        child: Container(
          color: Colors.teal,
          width: tableSize,
          height: tableSize,
          child: CustomPaint(
            painter: TablePainter(_game.myPeerId, _game.table, _uiImageMap),
          ),
        )));

    if (showStageAndPlayerInfo) {
      for (final widget in buildPlayerStateTiles(tableSize, scale)) {
        stacks.add(widget);
      }
      stacks.add(Transform.translate(
          offset: const Offset(0, 40),
          child: StageInfoWidget(
            table: _game.table,
            imageMap: _imageMap,
          )));
    }

    final widgets = <Widget>[];
    widgets.add(Stack(
      children: stacks,
      alignment: Alignment.center,
    ));
    const widgetH = (49 * 2 - 16.0) / tappableTileScale;
    late Widget tilesWidget;

    print("buildBody: _game.state: ${_game.state}");
    print("buildBody: _game.member: ${_game.member}");
    print("buildBody: _game.lostPlayerNames: ${_game.lostPlayerNames}");
    print("buildBody: _game.table.state: ${_game.table.state}");
    print("buildBody: _game.myPeerId: ${_game.myPeerId}");
    print("buildBody: _game.table.playerDataMap: ${_game.table.playerDataMap}");

    if (_game.myTurnTempState.onCalledFor == "lateKanStep2") {
      tilesWidget = MyCalledTilesWidget(
        gameData: _game,
        imageMap: _imageMap,
      );
    } else {
      tilesWidget = MyWallWidget(
        gameData: _game,
        imageMap: _imageMap,
      );
    }
    widgets
        .add(SizedBox(width: tableSize, height: widgetH, child: tilesWidget));

    widgets.add(SizedBox(
      width: tableSize,
      child: TableRibbonWidget(gameData: _game),
    ));

    return Column(
      children: widgets,
    );
  }

  void onTileImageLoaded(
      Map<String, ui.Image> uiImageMap, Map<String, Image> imageMap) {
    setState(() {
      _uiImageMap.addAll(uiImageMap);
      _imageMap.addAll(imageMap);
    });
  }

  List<Widget> buildPlayerStateTiles(double tableSize, double scale) {
    final playerOrder = _game.table.playerDataMap.keys.toList();
    final baseIndex = playerOrder.indexOf(_game.myPeerId);
    final leaderBaseIndex = _game.table.leaderChangeCount % 4;

    final winds = [
      "東",
      "南",
      "西",
      "北",
    ];
    final baseOffset = tableSize / 2 - scale * 35 - 30;
    final subOffset = scale * 20;
    final offsets = [
      Offset(0, baseOffset - subOffset),
      Offset(baseOffset, 0),
      Offset(0, -baseOffset),
      Offset(-baseOffset, 0),
    ];
    final angles = [
      0.0,
      -pi / 2,
      pi,
      pi / 2,
    ];

    final widgets = <Widget>[];
    for (int direction = 0; direction < 4; direction++) {
      final index = (direction + baseIndex) % 4;
      final leaderIndex = (4 + (index - leaderBaseIndex)) % 4;
      final peerId = playerOrder[index];
      final data = _game.table.playerDataMap[peerId]!;
      final turned = _game.table.turnedPeerId == peerId;
      widgets.add(Transform.translate(
          offset: offsets[direction],
          child: Transform.rotate(
              angle: angles[direction],
              child: PlayerStateTile(winds[leaderIndex], data.name, data.score,
                  data.existRiichiBar, turned))));
    }

    return widgets;
  }
}

class TablePainter extends CustomPainter {
  TablePainter(this._myPeerId, this._tableData, this._imageMap) {
    _tilesPainter = TilesPainter(_myPeerId, _tableData, _imageMap);
  }

  late TilesPainter _tilesPainter;
  final Map<String, ui.Image> _imageMap;
  final String _myPeerId;
  final tbl.Table _tableData;

  @override
  void paint(Canvas canvas, Size size) {
    _tilesPainter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
