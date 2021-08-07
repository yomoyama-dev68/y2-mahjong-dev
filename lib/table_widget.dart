import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'package:web_app_sample/game_controller.dart' as game;

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

    for (var direction = 0; direction < 4; direction++) {
      final other = (playerIndex + direction) % 4;
      final data = _table.playerDataMap[keyList[other]]!;

      data.calledTiles.add(game.CalledTiles(
          11, keyList[(other + 1) % 4], [36 + 6, 36 + 8], "pong"));
      data.calledTiles.add(
          game.CalledTiles(12, keyList[(other + 3) % 4], [12, 12, 12], "close-kan"));
      data.calledTiles.add(game.CalledTiles(
          16, keyList[(other + 2) % 4], [36 + 6, 36 + 8], "pong"));
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

class TileImages {
  TileImages(this._onLoaded) {
    _loadTiles("manzu_all/p_ms", 0, 9);
    _loadTiles("pinzu_all/p_ps", 1, 9);
    _loadTiles("sozu_all/p_ss", 2, 9);
    _loadTiles("tupai_all/p_ji", 3, 7);
    _loadTiles("ms_all/p_bk", 4, 1);
  }

  final Function(Map<String, ui.Image>) _onLoaded;
  final Map<String, ui.Image> imageMap = {};

  void _loadTiles(String prefix, int tileType, int tileNumberMax) {
    // Tile number.
    for (var i = 0; i < tileNumberMax; i++) {
      // Direction 0: 自牌（上向）1: 打牌（上向）2: 打牌（下向）3: 打牌（左向）4: 打牌（右向）
      for (var direction = 0; direction < 5; direction++) {
        // リーチ牌画像取得の簡単さのため、並び順を変更する。
        // Converted direction 0: 打牌（上向）1: 打牌（左向）2: 打牌（下向）3: 打牌（右向）4: 自牌（上向）
        var converted = 0;
        if (direction == 0) converted = 4;
        if (direction == 1) converted = 0;
        if (direction == 2) converted = 2;
        if (direction == 3) converted = 1;
        if (direction == 4) converted = 3;

        final key = '${tileType}_${i}_${converted}';
        final url = 'images/${prefix}${i + 1}_${direction}.gif';
        // print(url);
        rootBundle.load(url).then((data) {
          ui.decodeImageFromList(data.buffer.asUint8List(), (ui.Image img) {
            _onLoadedImage(key, img);
          });
        });
      }
    }
  }

  void _onLoadedImage(String key, ui.Image img) {
    imageMap[key] = img;
    const quantity = 9 * 5 * 3 + 7 * 5 + 1 * 5;
    //print("loading: [${imageMap.length}/${quantity}]");
    if (imageMap.length == quantity) {
      // 全部ロード完了
      //print("completed loading images.");
      _onLoaded(imageMap);
    }
  }
}

class TileInfo {
  TileInfo(int tileId) {
    if (tileId< 0) {
      type = 4;
      number = 0;
    } else {
      const tilesQuantityWithOutTupai = 4 * 9 * 3;
      final tupai = tileId > tilesQuantityWithOutTupai;
      type = tupai ? 3 : tileId ~/ (4 * 9); // 0:萬子, 1:筒子, 2,:索子, 3:字牌
      number = tupai
          ? (tileId - tilesQuantityWithOutTupai) % 7
          : tileId % 9; // 萬子, 筒子, 索子:9種 字牌: 7種
    }
  }

  late int type; // 0:萬子, 1:筒子, 2,:索子, 3:字牌, 4:伏牌
  late int number; // [萬子, 筒子, 索子]: 9種, [字牌]: 7種, [伏牌] 1種
}

class DrawObject {
  DrawObject(this.image, this.pos, this.isCalled);

  final ui.Image image;
  final Offset pos;
  final bool isCalled;
}

class TablePainter extends CustomPainter {
  TablePainter(this._tableData, this._imageMap);

  final game.Table _tableData; // <PeerId, プレイヤーデータ> 親順ソート済み
  final Map<String, ui.Image> _imageMap;

  void drawDiscardTiles(Canvas canvas, Size size, game.PlayerData data) {
    final drawObjects = <DrawObject>[];

    const centerSize = 33 * 3 * 1.0;
    for (var direction = 0; direction < 4; direction++) {
      drawDiscardTilesPerDirection(drawObjects, data, direction,
          size.center(centerOffset(direction, centerSize)));
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));
    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  bool isPortrait(int direction) {
    return direction % 2 == 0;
  }

  Offset centerOffset(int direction, double centerSize) {
    if (direction == 0) return Offset(-centerSize, centerSize);
    if (direction == 1) return Offset(centerSize, centerSize);
    if (direction == 2) return Offset(centerSize, -centerSize + 14);
    if (direction == 3) return Offset(-centerSize, -centerSize);
    assert(false);
    return Offset(0, 0);
  }

  int stepRowPos(int direction, ui.Image image, int tileThickness) {
    if (direction == 0) return (image.height - tileThickness);
    if (direction == 1) return (image.width);
    if (direction == 2) return -(image.height - tileThickness);
    if (direction == 3) return -(image.width);
    assert(false);
    return 0;
  }

  int varRowPosToRowPos(int direction, ui.Image image, varRowPos) {
    if (direction == 0) return (varRowPos);
    if (direction == 1) return (varRowPos);
    if (direction == 2) return (varRowPos - image.height);
    if (direction == 3) return (varRowPos - image.width);
    assert(false);
    return 0;
  }

  int varColPosToColPos(int direction, ui.Image image, varColPos) {
    if (direction == 0) return (varColPos);
    if (direction == 1) return (varColPos - image.height);
    if (direction == 2) return (varColPos - image.width);
    if (direction == 3) return (varColPos);
    assert(false);
    return 0;
  }

  int stepColPos(int direction, ui.Image image) {
    if (direction == 0) return (image.width);
    if (direction == 1) return -(image.height);
    if (direction == 2) return -(image.width);
    if (direction == 3) return (image.height);
    assert(false);
    return 0;
  }

  void drawDiscardTilesPerDirection(List<DrawObject> drawObjects,
      game.PlayerData data, int direction, Offset originOffset) {
    final baseColPos =
        isPortrait(direction) ? originOffset.dx : originOffset.dy;
    final baseRowPos =
        isPortrait(direction) ? originOffset.dy : originOffset.dx;

    var varColPos = baseColPos;
    for (var index = 0; index < data.discardedTiles.length; index++) {
      final tile = data.discardedTiles[index];
      final isRiichi = data.riichiTile.contains(tile);
      final isCalled = data.calledTilesByOther.contains(tile);
      final tileDirection = isRiichi ? (direction + 1) % 4 : direction;
      final tileThickness = isPortrait(tileDirection) ? 14 : 16;
      final image = getTileImage(tile, tileDirection);

      final rows = index ~/ 6;
      final varRowPos =
          baseRowPos + rows * stepRowPos(direction, image, tileThickness);
      final rowPos = varRowPosToRowPos(direction, image, varRowPos).toDouble();

      if (index % 6 == 0) {
        varColPos = baseColPos; // 行が変わる毎にリセット
      }
      if (direction == 1) varColPos += tileThickness;
      final colPos = varColPosToColPos(direction, image, varColPos).toDouble();
      final drawPos = isPortrait(direction)
          ? Offset(colPos, rowPos)
          : Offset(rowPos, colPos);
      drawObjects.add(DrawObject(image, drawPos, isCalled));

      varColPos += stepColPos(direction, image);
      if (direction == 3) varColPos -= tileThickness;
    }
  }

  void drawCalledTiles(Canvas canvas, Size size) {
    final drawObjects = <DrawObject>[];

    final keyList = _tableData.playerDataMap.keys.toList();

    final baseDirection = keyList.indexOf(_tableData.myPeerId);
    for (var direction = 0; direction < 4; direction++) {
      final index = (baseDirection + direction) % 4;
      final data = _tableData.playerDataMap[keyList[index]]!;
      drawCalledTilesPerDirection(
          drawObjects, data, direction, offsetForCall(direction, size));
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));
    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  Offset offsetForCall(int direction, Size size) {
    if (direction == 0) return Offset(size.width - 5, size.height - 5);
    if (direction == 1) return Offset(size.width - 5, 5);
    if (direction == 2) return const Offset(5, 5);
    if (direction == 3) return Offset(5, size.height - 5 - 14);
    assert(false);
    return const Offset(0, 0);
  }

  Offset steForCall(int direction) {
    if (direction == 0) return const Offset(-5, 0);
    if (direction == 1) return const Offset(0, 5);
    if (direction == 2) return const Offset(5, 0);
    if (direction == 3) return const Offset(0, -5);
    assert(false);
    return const Offset(0, 0);
  }

  void drawCalledTilesPerDirection(List<DrawObject> drawObjects,
      game.PlayerData data, int direction, Offset baseOffset) {
    for (var index = 0; index < data.calledTiles.length; index++) {
      final tiles = data.calledTiles[index];
      if (tiles.callAs == "late-kan") {
        baseOffset = drawCalledTilesLateKanPerDirection(
            drawObjects, tiles, direction, baseOffset);
      } else if (tiles.callAs == "open-kan") {
        baseOffset = drawCalledTilesOpenKanPerDirection(
            drawObjects, tiles, direction, baseOffset);
      } else if (tiles.callAs == "close-kan") {
        baseOffset = drawCalledTilesCloseKanPerDirection(
            drawObjects, tiles, direction, baseOffset);
      } else {
        baseOffset = drawCalledTilesPongChowPerDirection(
            drawObjects, tiles, direction, baseOffset);
      }
      baseOffset = baseOffset + steForCall(direction);
    }
  }

  Offset offsetDrawPongChow(int direction, ui.Image image) {
    // return Offset(dx: Col, dy: Row)
    if (direction == 0) {
      return Offset(-image.width.toDouble(), -image.height.toDouble());
    }
    if (direction == 1) return Offset(0, -image.width.toDouble());
    if (direction == 2) return const Offset(0, 0);
    if (direction == 3) return Offset(-image.height.toDouble(), 0);
    assert(false);
    return const Offset(0, 0);
  }

  Offset offsetDrawAddKan(int direction, ui.Image image, int stepMode, int tileThickness) {
    // return Offset(dx: Col, dy: Row)
    final base = offsetDrawPongChow(direction, image);
    if (stepMode != 2) {
      return base;
    }

    if (direction == 0) return base.translate(0, -image.height.toDouble() + tileThickness);
    if (direction == 1) return base.translate(0, -image.width.toDouble());
    if (direction == 2) return base.translate(0, image.height.toDouble() - tileThickness);
    if (direction == 3) return base.translate(0, image.width.toDouble());
    assert(false);
    return const Offset(0, 0);
  }

  int stepColForDrawPongChow(int direction, ui.Image image, int tileThickness) {
    if (direction == 0) return -image.width;
    if (direction == 1) return (image.height - tileThickness * 0);
    if (direction == 2) return image.width;
    if (direction == 3) return -(image.height - tileThickness * 0);
    assert(false);
    return 0;
  }

  Offset drawCalledTilesPongChowPerDirection(List<DrawObject> drawObjects,
      game.CalledTiles tiles, int direction, Offset baseOffset) {
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    print('$peerId ${tiles.calledFrom} ${callDirection}');
    assert(callDirection != 0);

    final calledTileDirection = (direction + 1) % 4;
    final tileDirectionMap = <List<int>>[]; // direction, tile
    tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
    tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
    tileDirectionMap
        .insert(callDirection - 1, [calledTileDirection, tiles.calledTile]);

    var baseColPos = isPortrait(direction) ? baseOffset.dx : baseOffset.dy;
    var baseRowPos = isPortrait(direction) ? baseOffset.dy : baseOffset.dx;

    for (final map in tileDirectionMap) {
      final tile = map[1];
      final tileDirection = map[0];
      final tileThickness = isPortrait(tileDirection) ? 14 : 16;
      final image = getTileImage(tile, tileDirection);

      if (direction == 3) baseColPos += tileThickness;

      final posOffset = offsetDrawPongChow(direction, image);
      final colPos = baseColPos + posOffset.dx;
      final rowPos = baseRowPos + posOffset.dy;

      final drawPos = isPortrait(direction)
          ? Offset(colPos, rowPos)
          : Offset(rowPos, colPos);
      drawObjects.add(DrawObject(image, drawPos, false));

      baseColPos += stepColForDrawPongChow(direction, image, tileThickness);
      if (direction == 1) baseColPos += -tileThickness;
    }

    return isPortrait(direction)
        ? Offset(baseColPos, baseRowPos)
        : Offset(baseRowPos, baseColPos);
  }

  Offset drawCalledTilesLateKanPerDirection(List<DrawObject> drawObjects,
      game.CalledTiles tiles, int direction, Offset baseOffset) {
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    assert(callDirection != 0);

    final calledTileDirection = (direction + 1) % 4;
    final tileDirectionMap = <List<int>>[]; // [direction, tile, step mode]
    tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
    tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
    tileDirectionMap
        .insert(callDirection - 1, [calledTileDirection, tiles.calledTile, 1]);
    tileDirectionMap.insert(
        callDirection, [calledTileDirection, tiles.selectedTiles[2], 2]);

    var baseColPos = isPortrait(direction) ? baseOffset.dx : baseOffset.dy;
    var baseRowPos = isPortrait(direction) ? baseOffset.dy : baseOffset.dx;

    for (final map in tileDirectionMap) {
      final tile = map[1];
      final tileDirection = map[0];
      final stepMode = map[2];
      final tileThickness = isPortrait(tileDirection) ? 14 : 16;
      final image = getTileImage(tile, tileDirection);

      if (stepMode != 2) {
        if (direction == 3) baseColPos += tileThickness;
      }

      final posOffset = offsetDrawAddKan(direction, image, stepMode, tileThickness);
      final colPos = baseColPos + posOffset.dx;
      var rowPos = baseRowPos + posOffset.dy;

      final drawPos = isPortrait(direction)
          ? Offset(colPos, rowPos)
          : Offset(rowPos, colPos);
      drawObjects.add(DrawObject(image, drawPos, false));

      if (stepMode != 1) {
        baseColPos += stepColForDrawPongChow(direction, image, tileThickness);
        if (direction == 1) baseColPos += -tileThickness;
      }
    }

    return isPortrait(direction)
        ? Offset(baseColPos, baseRowPos)
        : Offset(baseRowPos, baseColPos);
  }

  Offset drawCalledTilesOpenKanPerDirection(List<DrawObject> drawObjects,
      game.CalledTiles tiles, int direction, Offset baseOffset) {
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    assert(callDirection != 0);

    final calledTileDirection = (direction + 1) % 4;
    final tileDirectionMap = <List<int>>[]; // [direction, tile, step mode]
    tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
    tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
    tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    if (callDirection == 3) {
      tileDirectionMap.add([calledTileDirection, tiles.calledTile, 0]);
    } else {
      tileDirectionMap
          .insert(callDirection - 1, [calledTileDirection, tiles.calledTile, 0]);
    }

    var baseColPos = isPortrait(direction) ? baseOffset.dx : baseOffset.dy;
    var baseRowPos = isPortrait(direction) ? baseOffset.dy : baseOffset.dx;

    for (final map in tileDirectionMap) {
      final tile = map[1];
      final tileDirection = map[0];
      final stepMode = map[2];
      final tileThickness = isPortrait(tileDirection) ? 14 : 16;
      final image = getTileImage(tile, tileDirection);

      if (stepMode != 2) {
        if (direction == 3) baseColPos += tileThickness;
      }

      final posOffset = offsetDrawAddKan(direction, image, stepMode, tileThickness);
      final colPos = baseColPos + posOffset.dx;
      var rowPos = baseRowPos + posOffset.dy;

      final drawPos = isPortrait(direction)
          ? Offset(colPos, rowPos)
          : Offset(rowPos, colPos);
      drawObjects.add(DrawObject(image, drawPos, false));

      if (stepMode != 1) {
        baseColPos += stepColForDrawPongChow(direction, image, tileThickness);
        if (direction == 1) baseColPos += -tileThickness;
      }
    }

    return isPortrait(direction)
        ? Offset(baseColPos, baseRowPos)
        : Offset(baseRowPos, baseColPos);
  }

  Offset drawCalledTilesCloseKanPerDirection(List<DrawObject> drawObjects,
      game.CalledTiles tiles, int direction, Offset baseOffset) {
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    assert(callDirection != 0);

    final calledTileDirection = (direction + 1) % 4;
    final tileDirectionMap = <List<int>>[]; // [direction, tile, step mode]
    tileDirectionMap.add([direction, -1, 0]);
    tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
    tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    tileDirectionMap.add([direction, -1, 0]);

    var baseColPos = isPortrait(direction) ? baseOffset.dx : baseOffset.dy;
    var baseRowPos = isPortrait(direction) ? baseOffset.dy : baseOffset.dx;

    for (final map in tileDirectionMap) {
      final tile = map[1];
      final tileDirection = map[0];
      final stepMode = map[2];
      final tileThickness = isPortrait(tileDirection) ? 14 : 16;
      final image = getTileImage(tile, tileDirection);

      if (stepMode != 2) {
        if (direction == 3) baseColPos += tileThickness;
      }

      final posOffset = offsetDrawAddKan(direction, image, stepMode, tileThickness);
      final colPos = baseColPos + posOffset.dx;
      var rowPos = baseRowPos + posOffset.dy;

      final drawPos = isPortrait(direction)
          ? Offset(colPos, rowPos)
          : Offset(rowPos, colPos);
      drawObjects.add(DrawObject(image, drawPos, false));

      if (stepMode != 1) {
        baseColPos += stepColForDrawPongChow(direction, image, tileThickness);
        if (direction == 1) baseColPos += -tileThickness;
      }
    }

    return isPortrait(direction)
        ? Offset(baseColPos, baseRowPos)
        : Offset(baseRowPos, baseColPos);
  }

  ui.Image getTileImage(int tile, direction) {
    // direction = 0: 打牌(上向, 1: 打牌(左向, 2: 打牌(下向, 3: 打牌(右向, 4: 自牌(上向,
    final info = TileInfo(tile);
    final key = "${info.type}_${info.number}_${direction}";
    final image = _imageMap[key]!;
    return image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    drawDiscardTiles(canvas, size, _tableData.myData());
    drawCalledTiles(canvas, size);

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
