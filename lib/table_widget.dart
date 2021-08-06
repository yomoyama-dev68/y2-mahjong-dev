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
    _table.myPeerId = "AAAA";
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

    data.calledTiles.add(game.CalledTiles(11, "DDDD", [36+6, 36+8], "pong"));
    data.calledTiles.add(game.CalledTiles(12, "CCCC", [12, 12, 12], "kan"));
    data.calledTiles.add(game.CalledTiles(16, "BBBB", [36+6, 36+8], "pong"));
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
    for (final tile in _table
        .myData()
        .tiles) {
      widgets.add(
        Ink.image(
          image: Image
              .asset(tileToImageFileUrl(tile), scale: scale)
              .image,
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
    const tilesQuantityWithOutTupai = 4 * 9 * 3;
    final tupai = tileId > tilesQuantityWithOutTupai;
    type = tupai ? 3 : tileId ~/ (4 * 9); // 0:萬子, 1:筒子, 2,:索子, 3:字牌
    number = tupai
        ? (tileId - tilesQuantityWithOutTupai) % 7
        : tileId % 9; // 萬子, 筒子, 索子:9種 字牌: 7種
  }

  late int type; // 0:萬子, 1:筒子, 2,:索子, 3:字牌
  late int number; // [萬子, 筒子, 索子]: 9種, [字牌]: 7種
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

  void drewDiscardTilesForSelf(Canvas canvas, Size size, game.PlayerData data) {
    final direction = 0;
    final tileThickness = 14;

    final baseOffset = size.center(Offset(-33 * 3, 33 * 3));
    final drawObjects = <DrawObject>[];
    var basePosX = baseOffset.dx;
    for (var index = 0; index < data.discardedTiles.length; index++) {
      final tile = data.discardedTiles[index];
      final isRiichi = data.riichiTile.contains(tile);
      final isCalled = data.calledTilesByOther.contains(tile);
      final image =
      getTileImage(tile, isRiichi ? direction + 1 % 4 : direction);

      final rows = index ~/ 6;
      final pY = baseOffset.dy + rows * (image.height - tileThickness);
      if (index % 6 == 0) {
        basePosX = baseOffset.dx; // 行が変わる毎にリセット
      }
      final pX = basePosX;

      final adjustX = isRiichi ? 0 : 0;
      final adjustY = isRiichi ? 5 : 0;
      drawObjects
          .add(DrawObject(image, Offset(pX + adjustX, pY + adjustY), isCalled));
      basePosX += image.width + adjustX;
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));

    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  void drewDiscardTilesForRight(Canvas canvas, Size size,
      game.PlayerData data) {
    final direction = 1;
    final tileThickness = 16;

    final baseOffset =
    size.center(Offset(33 * 3, 33 * 3 + tileThickness.toDouble()));
    final drawObjects = <DrawObject>[];
    var basePosY = baseOffset.dy;
    for (var index = 0; index < data.discardedTiles.length; index++) {
      final tile = data.discardedTiles[index];
      final isRiichi = data.riichiTile.contains(tile);
      final isCalled = data.calledTilesByOther.contains(tile);
      final image =
      getTileImage(tile, isRiichi ? (direction + 1) % 4 : direction);

      final rows = index ~/ 6;
      final pX = baseOffset.dx + rows * image.width;
      if (index % 6 == 0) {
        basePosY = baseOffset.dy; // 行が変わる毎にリセット
      }
      final pY = basePosY - image.height;

      final adjustX = isRiichi ? 5 : 0;
      final adjustY = isRiichi ? 2 : 0;
      drawObjects
          .add(DrawObject(image, Offset(pX + adjustX, pY - adjustY), isCalled));
      basePosY -= (image.height - tileThickness) + adjustY;
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));

    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  void drewDiscardTilesForAgainst(Canvas canvas, Size size,
      game.PlayerData data) {
    final direction = 2;
    final tileThickness = 14;

    final baseOffset = size.center(Offset(33 * 3, -33 * 3 - 45));
    final drawObjects = <DrawObject>[];
    var basePosX = baseOffset.dx;
    for (var index = 0; index < data.discardedTiles.length; index++) {
      final tile = data.discardedTiles[index];
      final isRiichi = data.riichiTile.contains(tile);
      final isCalled = data.calledTilesByOther.contains(tile);
      final image =
      getTileImage(tile, isRiichi ? direction + 1 % 4 : direction);

      final rows = index ~/ 6;
      final pY = baseOffset.dy - rows * (image.height - tileThickness);
      if (index % 6 == 0) {
        basePosX = baseOffset.dx; // 行が変わる毎にリセット
      }
      final pX = basePosX - image.width;

      final adjustX = isRiichi ? 0 : 0;
      final adjustY = isRiichi ? 5 : 0;
      drawObjects
          .add(DrawObject(image, Offset(pX + adjustX, pY + adjustY), isCalled));
      basePosX -= image.width + adjustX;
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));

    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  void drewDiscardTilesForLeft(Canvas canvas, Size size, game.PlayerData data) {
    final direction = 3;
    final tileThickness = 16;

    final baseOffset = size.center(Offset(-33 * 3 - 33, -33 * 3));
    final drawObjects = <DrawObject>[];
    var basePosY = baseOffset.dy;
    for (var index = 0; index < data.discardedTiles.length; index++) {
      final tile = data.discardedTiles[index];
      final isRiichi = data.riichiTile.contains(tile);
      final isCalled = data.calledTilesByOther.contains(tile);
      final image =
      getTileImage(tile, isRiichi ? (direction + 1) % 4 : direction);

      final rows = index ~/ 6;
      final pX = baseOffset.dx - rows * image.width;
      if (index % 6 == 0) {
        basePosY = baseOffset.dy; // 行が変わる毎にリセット
      }
      final pY = basePosY;

      final adjustX = isRiichi ? 5 : 0;
      final adjustY = isRiichi ? 0 : 0;
      drawObjects
          .add(DrawObject(image, Offset(pX + adjustX, pY - adjustY), isCalled));
      basePosY += (image.height - tileThickness) + adjustY;
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));

    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  void drewCalledTilesForSelf(Canvas canvas, Size size, game.PlayerData data) {
    var baseOffset = Offset(size.width - 5, size.height - 5);
    final drawObjects = <DrawObject>[];
    for (var index = 0; index < data.calledTiles.length; index++) {
      final tiles = data.calledTiles[index];
      if (tiles.callAs == "kan") {
        baseOffset = drawKanSelf(baseOffset, tiles, drawObjects);
      } else {
        baseOffset = drawPongChowSelf(baseOffset, tiles, drawObjects);
      }
      baseOffset = Offset(baseOffset.dx - 5, baseOffset.dy);
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));

    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  Offset drawPongChowSelf(Offset baseOffset, game.CalledTiles tiles, drawObjects) {
    final direction = 0;
    final tileThickness = 16;
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    print('$peerId ${tiles.calledFrom} ${callDirection}');
    assert(callDirection != 0);

    final tileDirectionMap = <List<int>>[]; // direction, tile
    if (callDirection == 1) {
      tileDirectionMap.add([1, tiles.calledTile]);
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
    }
    if (callDirection == 2) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([1, tiles.calledTile]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
    }
    if (callDirection == 3) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
      tileDirectionMap.add([1, tiles.calledTile]);
    }

    var basePosX = baseOffset.dx;
    for (final map in tileDirectionMap) {
      final image = getTileImage(map[1], map[0]);
      final pX = basePosX - image.width;
      final pY = baseOffset.dy - image.height;
      drawObjects
          .add(DrawObject(image, Offset(pX, pY), false));
      basePosX -= image.width;
    }

    return Offset(basePosX, baseOffset.dy);
  }

  Offset drawKanSelf(Offset baseOffset, game.CalledTiles tiles, drawObjects) {
    final direction = 0;
    final tileThickness = 16;
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    assert(callDirection != 0);

    final tileDirectionMap = <List<int>>[]; // direction, tile, offset
    if (callDirection == 1) {
      tileDirectionMap.add([1, tiles.calledTile, 1]);
      tileDirectionMap.add([1, tiles.selectedTiles[0], 2]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    }
    if (callDirection == 2) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([1, tiles.calledTile, 1]);
      tileDirectionMap.add([1, tiles.selectedTiles[1], 2]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    }
    if (callDirection == 3) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([1, tiles.calledTile, 1]);
      tileDirectionMap.add([1, tiles.selectedTiles[2], 2]);
    }

    var basePosX = baseOffset.dx;
    for (final map in tileDirectionMap) {
      final image = getTileImage(map[1], map[0]);
      final pX = basePosX - image.width;
      final pY = map[2] == 2 ? baseOffset.dy - image.height * 2 + tileThickness : baseOffset.dy - image.height;
      drawObjects
          .add(DrawObject(image, Offset(pX, pY), false));
      if (map[2] !=1 ) {
        basePosX -= image.width;
      }
    }

    return Offset(basePosX, baseOffset.dy);
  }

  void drewCalledTilesForRight(Canvas canvas, Size size, game.PlayerData data) {
    var baseOffset = Offset(size.width - 5, 5);
    final drawObjects = <DrawObject>[];
    for (var index = 0; index < data.calledTiles.length; index++) {
      final tiles = data.calledTiles[index];
      if (tiles.callAs == "kan") {
        baseOffset = drawKanRight(baseOffset, tiles, drawObjects);
      } else {
        baseOffset = drawPongChowRight(baseOffset, tiles, drawObjects);
      }
      baseOffset = Offset(baseOffset.dx, baseOffset.dy + 5);
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));

    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  Offset drawPongChowRight(Offset baseOffset, game.CalledTiles tiles, drawObjects) {
    final direction = 1;
    final tileThickness = 16;
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    print('$peerId ${tiles.calledFrom} ${callDirection}');
    assert(callDirection != 0);

    final tileDirectionMap = <List<int>>[]; // direction, tile
    if (callDirection == 1) {
      tileDirectionMap.add([2, tiles.calledTile]);
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
    }
    if (callDirection == 2) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([2, tiles.calledTile]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
    }
    if (callDirection == 3) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
      tileDirectionMap.add([2, tiles.calledTile]);
    }

    var basePosY = baseOffset.dy;
    for (final map in tileDirectionMap) {
      final image = getTileImage(map[1], map[0]);
      final pX = baseOffset.dx - image.width;
      final pY = basePosY;
      drawObjects
          .add(DrawObject(image, Offset(pX, pY), false));
      basePosY += image.height - tileThickness;
    }

    return Offset(baseOffset.dx, basePosY);
  }

  Offset drawKanRight(Offset baseOffset, game.CalledTiles tiles, drawObjects) {
    final direction = 1;
    final tileThickness = 16;
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    print('$peerId ${tiles.calledFrom} ${callDirection}');
    assert(callDirection != 0);

    final tileDirectionMap = <List<int>>[]; // direction, tile, offset
    if (callDirection == 1) {
      tileDirectionMap.add([2, tiles.calledTile, 1]);
      tileDirectionMap.add([2, tiles.selectedTiles[0], 2]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    }
    if (callDirection == 2) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([2, tiles.calledTile, 1]);
      tileDirectionMap.add([2, tiles.selectedTiles[1], 2]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    }
    if (callDirection == 3) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([2, tiles.calledTile, 1]);
      tileDirectionMap.add([2, tiles.selectedTiles[2], 2]);
    }

    var basePosY = baseOffset.dy;
    for (final map in tileDirectionMap) {
      final image = getTileImage(map[1], map[0]);

      final pX = map[2] == 2 ? baseOffset.dx - image.width * 2 : baseOffset.dx - image.width;
      final pY = basePosY;
      drawObjects
          .add(DrawObject(image, Offset(pX, pY), false));
      if (map[2] !=1 ) {
        basePosY += image.height - tileThickness;
      }
    }

    return Offset(baseOffset.dx, basePosY);
  }

  void drewCalledTilesForAgainst(Canvas canvas, Size size, game.PlayerData data) {
    var baseOffset = Offset(5, 5);
    final drawObjects = <DrawObject>[];
    for (var index = 0; index < data.calledTiles.length; index++) {
      final tiles = data.calledTiles[index];
      if (tiles.callAs == "kan") {
        baseOffset = drawKanAgainst(baseOffset, tiles, drawObjects);
      } else {
        baseOffset = drawPongChowAgainst(baseOffset, tiles, drawObjects);
      }
      baseOffset = Offset(baseOffset.dx + 5, baseOffset.dy);
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));

    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  Offset drawPongChowAgainst(Offset baseOffset, game.CalledTiles tiles, drawObjects) {
    final direction = 2;
    final tileThickness = 14;
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    print('$peerId ${tiles.calledFrom} ${callDirection}');
    assert(callDirection != 0);

    final tileDirectionMap = <List<int>>[]; // direction, tile
    if (callDirection == 1) {
      tileDirectionMap.add([3, tiles.calledTile]);
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
    }
    if (callDirection == 2) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([3, tiles.calledTile]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
    }
    if (callDirection == 3) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
      tileDirectionMap.add([3, tiles.calledTile]);
    }

    var basePosX = baseOffset.dx;
    for (final map in tileDirectionMap) {
      final image = getTileImage(map[1], map[0]);
      final pX = basePosX;
      final pY = baseOffset.dy;
      drawObjects
          .add(DrawObject(image, Offset(pX, pY), false));
      basePosX += image.width;
    }

    return Offset(basePosX, baseOffset.dy);
  }

  Offset drawKanAgainst(Offset baseOffset, game.CalledTiles tiles, drawObjects) {
    final direction = 2;
    final tileThickness = 16;
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    print('$peerId ${tiles.calledFrom} ${callDirection}');
    assert(callDirection != 0);

    final tileDirectionMap = <List<int>>[]; // direction, tile, offset
    if (callDirection == 1) {
      tileDirectionMap.add([3, tiles.calledTile, 1]);
      tileDirectionMap.add([3, tiles.selectedTiles[0], 2]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    }
    if (callDirection == 2) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([3, tiles.calledTile, 1]);
      tileDirectionMap.add([3, tiles.selectedTiles[1], 2]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    }
    if (callDirection == 3) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([3, tiles.calledTile, 1]);
      tileDirectionMap.add([3, tiles.selectedTiles[2], 2]);
    }

    var basePosX = baseOffset.dx;
    for (final map in tileDirectionMap) {
      final image = getTileImage(map[1], map[0]);

      final pX = basePosX;
      final pY = map[2] == 2 ? baseOffset.dy + image.height - tileThickness : baseOffset.dy;
      drawObjects
          .add(DrawObject(image, Offset(pX, pY), false));
      if (map[2] !=1 ) {
        basePosX += image.width;
      }
    }

    return Offset(basePosX, baseOffset.dy);
  }

  void drewCalledTilesForLeft(Canvas canvas, Size size, game.PlayerData data) {
    var baseOffset = Offset(5, size.height - 33);
    final drawObjects = <DrawObject>[];
    for (var index = 0; index < data.calledTiles.length; index++) {
      final tiles = data.calledTiles[index];
      if (tiles.callAs == "kan") {
        baseOffset = drawKanLeft(baseOffset, tiles, drawObjects);
      } else {
        baseOffset = drawPongChowLeft(baseOffset, tiles, drawObjects);
      }
      baseOffset = Offset(baseOffset.dx, baseOffset.dy - 5);
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));

    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  Offset drawPongChowLeft(Offset baseOffset, game.CalledTiles tiles, drawObjects) {
    final direction = 3;
    final tileThickness = 16;
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    print('$peerId ${tiles.calledFrom} ${callDirection}');
    assert(callDirection != 0);

    final tileDirectionMap = <List<int>>[]; // direction, tile
    if (callDirection == 1) {
      tileDirectionMap.add([0, tiles.calledTile]);
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
    }
    if (callDirection == 2) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([0, tiles.calledTile]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
    }
    if (callDirection == 3) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0]]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1]]);
      tileDirectionMap.add([0, tiles.calledTile]);
    }

    var basePosY = baseOffset.dy;
    for (final map in tileDirectionMap) {
      final image = getTileImage(map[1], map[0]);
      final pX = baseOffset.dx;
      final pY = basePosY - image.height;
      drawObjects
          .add(DrawObject(image, Offset(pX, pY), false));
      basePosY -= image.height - tileThickness;
    }

    return Offset(baseOffset.dx, basePosY);
  }

  Offset drawKanLeft(Offset baseOffset, game.CalledTiles tiles, drawObjects) {
    final direction = 3;
    final tileThickness = 16;
    final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = _tableData.direction(peerId, tiles.calledFrom);
    print('$peerId ${tiles.calledFrom} ${callDirection}');
    assert(callDirection != 0);

    final tileDirectionMap = <List<int>>[]; // direction, tile, offset
    if (callDirection == 1) {
      tileDirectionMap.add([0, tiles.calledTile, 1]);
      tileDirectionMap.add([0, tiles.selectedTiles[0], 2]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    }
    if (callDirection == 2) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([0, tiles.calledTile, 1]);
      tileDirectionMap.add([0, tiles.selectedTiles[1], 2]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
    }
    if (callDirection == 3) {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([0, tiles.calledTile, 1]);
      tileDirectionMap.add([0, tiles.selectedTiles[2], 2]);
    }

    var basePosY = baseOffset.dy;
    for (final map in tileDirectionMap) {
      final image = getTileImage(map[1], map[0]);

      final pX = map[2] == 2 ? baseOffset.dx + image.width : baseOffset.dx;
      final pY = basePosY - image.height;
      drawObjects
          .add(DrawObject(image, Offset(pX, pY), false));
      if (map[2] !=1 ) {
        basePosY -= image.height - tileThickness;
      }
    }

    return Offset(baseOffset.dx, basePosY);
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
    drewDiscardTilesForSelf(canvas, size, _tableData.myData());
    drewDiscardTilesForRight(canvas, size, _tableData.myData());
    drewDiscardTilesForAgainst(canvas, size, _tableData.myData());
    drewDiscardTilesForLeft(canvas, size, _tableData.myData());
    drewCalledTilesForSelf(canvas, size, _tableData.myData());
    // drewCalledTilesForRight(canvas, size, _tableData.myData());
    // drewCalledTilesForAgainst(canvas, size, _tableData.myData());
    // drewCalledTilesForLeft(canvas, size, _tableData.myData());
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
