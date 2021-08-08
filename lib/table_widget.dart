import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'package:web_app_sample/game_controller.dart' as game;
import 'package:web_app_sample/tiles_painter.dart';

class GameTableWidget extends StatefulWidget {
  const GameTableWidget({Key? key}) : super(key: key);

  @override
  _GameTableWidgetState createState() => _GameTableWidgetState();
}

class _GameTableWidgetState extends State<GameTableWidget> {
  final Map<String, ui.Image> _imageMap = {};
  final Map<String, ui.Image> _imageMap2 = {};

  late TileImages _tileImages;
  late game.Table _table;
  final _members = <String, String>{
    "AAAA": "Name1",
    "BBBB": "Name2",
    "CCCC": "Name3",
    "DDDD": "Name4",
  };

  @override
  void initState() {
    super.initState();
    _tileImages = TileImages(onTileImageLoaded);
    _table = game.Table(_members);
    int playerIndex = 0;
    final keyList = _table.playerDataMap.keys.toList();
    _table.myPeerId = keyList[playerIndex];

    _table.deadWallTiles.add(0);
    _table.deadWallTiles.add(1);
    _table.deadWallTiles.add(2);
    _table.deadWallTiles.add(3);
    _table.deadWallTiles.add(4);
    _table.deadWallTiles.add(5);
    _table.deadWallTiles.add(6);
    _table.deadWallTiles.add(7);
    _table.deadWallTiles.add(8);
    _table.deadWallTiles.add(9);

    final data = _table.playerDataMap[_table.myPeerId]!;
    data.discardedTiles.add(0);
    data.discardedTiles.add(1);
    data.discardedTiles.add(2);
    data.discardedTiles.add(3);
    data.discardedTiles.add(4);
    data.discardedTiles.add(5);
    data.discardedTiles.add(6);
    data.discardedTiles.add(7);
    data.discardedTiles.add(8);
    data.discardedTiles.add((9 * 4) * 1 + 0);
    data.discardedTiles.add((9 * 4) * 1 + 1);
    data.discardedTiles.add((9 * 4) * 2 + 0);
    data.discardedTiles.add((9 * 4) * 2 + 1);

    data.riichiTile.add(4);

    data.tiles.add(0);
    data.tiles.add(1);
    data.tiles.add(2);
    data.tiles.add(3);
    data.tiles.add(4);
    data.tiles.add(5);
    data.tiles.add(6);
    data.tiles.add(7);
    data.tiles.add(8);
    data.tiles.add(9);
    data.tiles.add(10);
    data.tiles.add(11);
    data.tiles.add(12);

    data.drewTile.add(12);

    for (var direction = 0; direction < 4; direction++) {
      final other = (playerIndex + direction) % 4;
      final data = _table.playerDataMap[keyList[other]]!;

      data.calledTiles.add(game.CalledTiles(
          11, keyList[(other + 3) % 4], [36 + 6, 36 + 8], "pong"));
      data.calledTiles.add(game.CalledTiles(
          12, keyList[(other + 3) % 4], [12, 12, 12], "late-kan"));
      data.calledTiles.add(game.CalledTiles(
          16, keyList[(other + 1) % 4], [36 + 6, 36 + 8], "pong"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildBody();
  }

  Widget buildBody() {
    if (_imageMap.isEmpty) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        Container(
          color: Colors.teal,
          width: 700,
          height: 700,
          child: CustomPaint(
            painter: TablePainter(_table, _imageMap),
          ),
        ),
        Row(
          children: myTiles(),
        )
      ],
    );
  }

  List<Widget> myTiles() {
    final widgets = <Widget>[];
    const scale = 0.8;
    for (final tile in _table.myData().tiles) {
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
    final info = TileInfo(tile);
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
  TablePainter(this._tableData, this._imageMap) {
    _tilesPainter = TilesPainter(_tableData, _imageMap);
  }

  late TilesPainter _tilesPainter;
  final game.Table _tableData; // <PeerId, プレイヤーデータ> 親順ソート済み
  final Map<String, ui.Image> _imageMap;

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
