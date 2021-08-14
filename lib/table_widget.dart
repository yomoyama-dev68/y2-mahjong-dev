import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'game_controller.dart' as game;
import 'name_set_dialog.dart';
import 'table_controller.dart' as tbl;
import 'tiles_painter.dart';
import 'table_ribbon_widget.dart';

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
    print("onChangeTableState ${_game.myName()} ${_game.state}");
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
    if (_game.isTradingScore) {
      stacks.add(SizedBox(width: 350, child: buildTradingScoreWidget()));
    }
    final myData = _game.table.playerDataMap[_game.myPeerId];
    if (myData != null && myData.requestingScoreFrom.isNotEmpty) {
      stacks.add(SizedBox(
          width: 350,
          child: buildAcceptTradingScoreWidget(myData.requestingScoreFrom)));
    }

    return Column(
      children: [
        Stack(
          children: stacks,
          alignment: Alignment.center,
        ),
        SizedBox(
          width: 700,
          child: TableRibbonWidget(gameData: _game),
        ),
      ],
    );
  }

  Widget buildAcceptTradingScoreWidget(Map<String, int> requestingScoreFrom) {
    final widgets = <Widget>[
      const Text("点棒支払を受け入れますか？"),
      const SizedBox(
        height: 10,
      )
    ];

    final textControllerMap = <String, TextEditingController>{};

    for (final e in _game.member.entries) {
      if (_game.myPeerId == e.key) continue;
      if (!requestingScoreFrom.containsKey(e.key)) continue;
      final score = requestingScoreFrom[e.key].toString();
      final textController = TextEditingController();
      textControllerMap[e.key] = textController;
      textController.text = score;
      widgets.add(TextField(
        controller: textController,
        readOnly: true,
        decoration: InputDecoration(
            labelText: "${e.value}から", border: OutlineInputBorder()),
      ));
      widgets.add(const SizedBox(
        height: 10,
      ));
    }

    widgets.add(Row(children: [
      Spacer(),
      ElevatedButton(
        child: const Text("No"),
        onPressed: () {_game.refuseRequestedScore();},
      ),
      const SizedBox(
        width: 5,
      ),
      ElevatedButton(
        child: const Text("OK"),
        onPressed: () {_game.acceptRequestedScore();},
      )
    ]));
    return Container(
      padding: const EdgeInsets.all(5),
      child: Column(children: widgets),
      color: Colors.white,
    );
  }

  Widget buildTradingScoreWidget() {
    final widgets = <Widget>[
      const Text("点棒支払"),
      const SizedBox(
        height: 10,
      )
    ];

    final textControllerMap = <String, TextEditingController>{};

    for (final e in _game.member.entries) {
      final textController = TextEditingController();
      if (_game.myPeerId == e.key) continue;
      textControllerMap[e.key] = textController;
      widgets.add(TextField(
        controller: textController,
        decoration: InputDecoration(
            labelText: "${e.value}へ", border: OutlineInputBorder()),
        autofocus: true,
        keyboardType: TextInputType.number,
      ));
      widgets.add(const SizedBox(
        height: 10,
      ));
    }

    widgets.add(Row(children: [
      Spacer(),
      ElevatedButton(
        child: const Text("Cancel"),
        onPressed: () {
          _game.cancelTradingScore();
        },
      ),
      const SizedBox(
        width: 5,
      ),
      ElevatedButton(
        child: const Text("OK"),
        onPressed: () {
          final request = textControllerMap.map(
              (key, value) => MapEntry(key, int.tryParse(value.text) ?? 0));
          request.removeWhere((key, value) => value == 0);
          _game.requestScore(request);
        },
      )
    ]));
    return Container(
      padding: const EdgeInsets.all(5),
      child: Column(children: widgets),
      color: Colors.white,
    );
  }

  void onTileImageLoaded(Map<String, ui.Image> imageMap) {
    setState(() {
      _imageMap.addAll(imageMap);
    });
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

    final paint = Paint();
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
