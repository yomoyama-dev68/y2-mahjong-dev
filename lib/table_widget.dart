import 'package:flutter/material.dart';
import 'package:web_app_sample/player_state_tile.dart';
import 'package:web_app_sample/trading_score_widget.dart';
import 'dart:ui' as ui;

import 'game_controller.dart' as game;
import 'name_set_dialog.dart';
import 'table_controller.dart' as tbl;
import 'tiles_painter.dart';
import 'table_ribbon_widget.dart';
import 'mywall_widget.dart';
import 'dart:math';

class GameTableWidget extends StatefulWidget {
  const GameTableWidget({Key? key, required this.roomId, this.playerName})
      : super(key: key);

  final String roomId;
  final String? playerName;

  @override
  _GameTableWidgetState createState() => _GameTableWidgetState();
}

class _GameTableWidgetState extends State<GameTableWidget> {
  final Map<String, ui.Image> _imageMap = {};
  late game.Game _game;
  late game.State _lastState;

  @override
  void initState() {
    print("_GameTableWidgetState:initState");
    super.initState();
    final _tileImages = TileImages(onTileImageLoaded);
    _game = game.Game(widget.roomId, onChangeTableState);
    _lastState = _game.state;
  }

  void onChangeTableState() {
    setState(() {});
    // print("onChangeTableState ${_game.myName()} ${_game.state}");
    if (_lastState != _game.state) {
      _lastState = _game.state;
      if (_game.state == game.State.onSettingMyName) {
        _setMyName();
      }
    }
  }

  Future<void> _setMyName() async {
    if (widget.playerName != null) {
      _game.setMyName(widget.playerName!);
      return;
    }
    while (true) {
      final name = await NameSetDialog.show(context, _game.myName());
      if (name != null) {
        _game.setMyName(name);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageMap.isEmpty) {
      return buildWaitingView("Loading images.");
    }
    if (_game.state == game.State.onCreatingMyPeer) {
      return buildWaitingView("Creating my peer.");
    }
    if (_game.state == game.State.onJoiningRoom) {
      return buildWaitingView("Creating a game room.");
    }
    if (_game.state == game.State.onSettingMyName) {
      return buildWaitingView("Setting my player name.");
    }
    if (_game.state == game.State.onWaitingOtherPlayersForStart) {
      return buildWaitingView("Waiting other players.");
    }

    return buildBody();
  }

  Widget buildWaitingView(String message) {
    return Column(children: [Text(message), const CircularProgressIndicator()]);
  }

  Widget buildBody() {
    final stacks = <Widget>[];
    stacks.add(Container(
      color: Colors.teal,
      width: 700,
      height: 700,
      child: CustomPaint(
        painter: TablePainter(_game.myPeerId, _game.table, _imageMap),
      ),
    ));

    for (final widget in buildPlayerStateTiles()) {
      stacks.add(widget);
    }

    if (_game.handLocalState.onTradingScore) {
      stacks.add(SizedBox(
          width: 350, child: TradingScoreRequestWidget(gameData: _game)));
    }
    final myData = _game.table.playerDataMap[_game.myPeerId];
    if (myData != null && myData.requestingScoreFrom.isNotEmpty) {
      stacks.add(SizedBox(
          width: 350,
          child: TradingScoreAcceptWidget(
              gameData: _game,
              requestingScoreFrom: myData.requestingScoreFrom)));
    }

    final widgets = [
      Stack(
        children: stacks,
        alignment: Alignment.center,
      ),
      SizedBox(
        width: 700,
        child: TableRibbonWidget(gameData: _game),
      ),
    ];
    if (_game.table.isSelectingTileState()) {
      widgets.add(SizedBox(width: 700, child: MyWallWidget(gameData: _game)));
    }

    return Column(
      children: widgets,
    );
  }

  void onTileImageLoaded(Map<String, ui.Image> imageMap) {
    setState(() {
      _imageMap.addAll(imageMap);
    });
  }

  List<Widget> buildPlayerStateTiles() {
    final playerOrder = _game.table.playerDataMap.keys.toList();
    final baseIndex = playerOrder.indexOf(_game.myPeerId);
    final leaderBaseIndex = _game.table.leaderChangeCount % 4;

    final winds = [
      "東",
      "南",
      "西",
      "北",
    ];
    final offsets = [
      const Offset(0, 260),
      const Offset(280, 0),
      const Offset(0, -280),
      const Offset(-280, 0),
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
      final data = _game.table.playerDataMap[playerOrder[index]]!;

      widgets.add(Transform.translate(
          offset: offsets[direction],
          child: Transform.rotate(
              angle: angles[direction],
              child: PlayerStateTile(winds[leaderIndex], data.name, data.score))));
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
