import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:web_app_sample/game_controller.dart' as game;
import 'name_set_dialog.dart';
import 'table_controller.dart' as tbl;
import 'package:web_app_sample/tiles_painter.dart';

class GameTableWidget extends StatefulWidget {
  const GameTableWidget({Key? key, required this.roomId}) : super(key: key);

  final String roomId;

  @override
  _GameTableWidgetState createState() => _GameTableWidgetState();
}

class _GameTableWidgetState extends State<GameTableWidget> {
  final Map<String, ui.Image> _imageMap = {};
  late game.Game _game;
  late game.State _lastState;

  @override
  void initState() {
    super.initState();
    final _tileImages = TileImages(onTileImageLoaded);
    _game = game.Game(widget.roomId, onChangeTableState);
    _lastState = _game.state;
  }

  void onChangeTableState() {
    setState(() {});
    if (_lastState != _game.state) {
      if (_game.state == game.State.onSettingMyName) {
        _setMyName();
      }
    }
    _lastState = _game.state;
  }

  Future<void> _setMyName() async {
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

    if (_game.state == game.State.onGame) {
      return const CircularProgressIndicator();
    }

    return buildBody();
  }

  Widget buildWaitingView(String message) {
    return Scaffold(
      body: Center(
          child: Column(
              children: [Text(message), const CircularProgressIndicator()])),
    );
  }

  Widget buildBody() {
    return Column(
      children: [
        Container(
          color: Colors.teal,
          width: 700,
          height: 700,
          child: CustomPaint(
            painter: TablePainter(_game.myPeerId, _game.table, _imageMap),
          ),
        ),
        SizedBox(
            width: 700,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: drawable(),
            )),
      ],
    );
  }

  // State:
  // nowSetup
  // callableFromOther
  // selectingTilesForPong
  // selectingTilesForChow
  // selectingTilesForOpenKan
  // finishingForLon
  // waitToDiscardOther
  // drawable
  // callableOnSelf
  // callableOnSelfInRiiching
  // selectingTilesForCloseKan
  // selectingTilesForLateKan
  // selectingTileForDiscard
  // finishingForTumo
  List<Widget> buildRibbonForCallableFromOther() {
    final widgets = <Widget>[];
    widgets
        .add(FloatingActionButton(child: const Text('ポン'), onPressed: () {}));
    widgets
        .add(FloatingActionButton(child: const Text('チー'), onPressed: () {}));
    widgets
        .add(FloatingActionButton(child: const Text('カン'), onPressed: () {}));
    widgets
        .add(FloatingActionButton(child: const Text('ロン'), onPressed: () {}));
    return widgets;
  }

  List<Widget> buildRibbonForSelectingTilesForPong() {
    return myTiles();
  }

  List<Widget> drawable() {
    final widgets = <Widget>[];
    widgets
        .add(FloatingActionButton(child: const Text('ドロー'), onPressed: () {}));
    return widgets;
  }

  List<Widget> callableOnSelf() {
    final widgets = <Widget>[];
    widgets
        .add(FloatingActionButton(child: const Text('カン'), onPressed: () {}));
    widgets
        .add(FloatingActionButton(child: const Text('リーチ'), onPressed: () {}));
    widgets
        .add(FloatingActionButton(child: const Text('ツモ'), onPressed: () {}));
    return widgets;
  }

  List<Widget> callableOnSelfInRiiching() {
    final widgets = <Widget>[];
    widgets
        .add(FloatingActionButton(child: const Text('カン'), onPressed: () {}));
    widgets
        .add(FloatingActionButton(child: const Text('リーチ'), onPressed: null));
    widgets
        .add(FloatingActionButton(child: const Text('ツモ'), onPressed: () {}));
    return widgets;
  }

  List<Widget> myTiles() {
    final widgets = <Widget>[];
    const scale = 0.8;
    for (final tile in _game.table.playerData(_game.myPeerId).tiles) {
      widgets.add(
        Ink.image(
          image: Image.asset(tileToImageFileUrl(tile), scale: scale).image,
          height: 59.0 / scale,
          width: 33.0 / scale,
          child: InkWell(
            onTap: () {},
            child: SizedBox(),
          ),
        ),
      );
    }
    return widgets;
  }

  String tileToImageFileUrl(int tile) {
    final info = tbl.TileInfo(tile);
    if (info.type == 0) {
      return "images/manzu_all/p_ms${info.number + 1}_0.gif";
    }
    if (info.type == 1) {
      return "images/pinzu_all/p_ps${info.number + 1}_0.gif";
    }
    if (info.type == 2) {
      return "images/sozu_all/p_ss${info.number + 1}_0.gif";
    }
    if (info.type == 3) {
      return "images/tupai_all/p_ji${info.number + 1}_0.gif";
    }
    return "";
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
