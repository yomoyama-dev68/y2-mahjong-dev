import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'table_controller.dart' as tbl;
import 'dart:ui' as ui;
import 'dart:math' as math;
/*
class TileImages {
  TileImages(this._onLoaded) {
    _loadTiles("manzu_all/p_ms", 0, 9);
    _loadTiles("pinzu_all/p_ps", 1, 9);
    _loadTiles("sozu_all/p_ss", 2, 9);
    _loadTiles("tupai_all/p_ji", 3, 7);
    _loadTiles("ms_all/p_bk", 4, 1);
    _loadRiichiBar();
    _loadStageTiles();
  }

  final Function(Map<String, ui.Image>, Map<String, Image>) _onLoaded;
  final Map<String, ui.Image> uiImageMap = {};
  final Map<String, Image> imageMap = {};

  void _loadRiichiBar() {
    _loadImage('riichibar_0', 'assets/images/ms_all/b_1_2.gif');
    _loadImage('riichibar_1', 'assets/images/ms_all/b_1_1.gif');
    _loadImage('riichibar_2', 'assets/images/ms_all/b_1_2.gif');
    _loadImage('riichibar_3', 'assets/images/ms_all/b_1_1.gif');
  }

  void _loadStageTiles() {
    _loadImage('stage_0_0', 'assets/images/ms_all/c_e_1.gif');
    _loadImage('stage_0_1', 'assets/images/ms_all/c_e_4.gif');
    _loadImage('stage_0_2', 'assets/images/ms_all/c_e_3.gif');
    _loadImage('stage_0_3', 'assets/images/ms_all/c_e_2.gif');

    _loadImage('stage_1_0', 'assets/images/ms_all/c_s_1.gif');
    _loadImage('stage_1_1', 'assets/images/ms_all/c_s_4.gif');
    _loadImage('stage_1_2', 'assets/images/ms_all/c_s_3.gif');
    _loadImage('stage_1_3', 'assets/images/ms_all/c_s_2.gif');

    _loadImage('stage_2_0', 'assets/images/ms_all/c_w_1.gif');
    _loadImage('stage_2_1', 'assets/images/ms_all/c_w_4.gif');
    _loadImage('stage_2_2', 'assets/images/ms_all/c_w_3.gif');
    _loadImage('stage_2_3', 'assets/images/ms_all/c_w_2.gif');

    _loadImage('stage_3_0', 'assets/images/ms_all/c_n_1.gif');
    _loadImage('stage_3_1', 'assets/images/ms_all/c_n_4.gif');
    _loadImage('stage_3_2', 'assets/images/ms_all/c_n_3.gif');
    _loadImage('stage_3_3', 'assets/images/ms_all/c_n_2.gif');
  }

  void _loadImage(String key, String url) {
    // print(url);
    rootBundle.load(url).then((data) {
      final img = Image.memory(data.buffer.asUint8List(), scale: 0.8);
      ui.decodeImageFromList(data.buffer.asUint8List(), (ui.Image uiImg) {
        _onLoadedImage(key, uiImg, img);
      });
    });
  }

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
        final url = 'assets/images/${prefix}${i + 1}_${direction}.gif';
        _loadImage(key, url);
      }
    }
  }

  void _onLoadedImage(String key, ui.Image uiImg, Image img) {
    uiImageMap[key] = uiImg;
    imageMap[key] = img;
    const quantity = 9 * 5 * 3 + 7 * 5 + 1 * 5 + 4 + 4 * 4;
    //print("loading: [${imageMap.length}/${quantity}]");
    if (uiImageMap.length == quantity) {
      // 全部ロード完了
      print("completed loading images.");
      _onLoaded(uiImageMap, imageMap);
    }
  }
}
*/

class DrawObject {
  DrawObject(this.image, this.pos, this.isCalled);

  final ui.Image image;
  final Offset pos;
  final bool isCalled;
}

class TilesPainter {
  TilesPainter(this.myPeerId, this._tableData, this._imageMap);

  final String myPeerId;
  final tbl.Table _tableData; // <PeerId, プレイヤーデータ> 親順ソート済み
  final Map<String, ui.Image> _imageMap;

  void drawOpenedTiles(Canvas canvas, Size size) {
    final drawObjects = <DrawObject>[];

    final keyList = _tableData.playerDataMap.keys.toList();
    final baseDirection = keyList.indexOf(myPeerId);
    for (var direction = 0; direction < 4; direction++) {
      final index = (baseDirection + direction) % 4;
      final data = _tableData.playerDataMap[keyList[index]]!;
      if (data.openTiles) {
        drawOpenedTilesPerDirection(drawObjects, data, direction,
            offsetForOpenedTiles(direction, size));
      }
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));
    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  Offset offsetForOpenedTiles(int direction, Size size) {
    final closeTileImage = getTileImage(0, direction);
    final tileWidth = closeTileImage.width.toDouble();
    final tileHeight = closeTileImage.height.toDouble();

    if (direction == 0) {
      return Offset(tileWidth * 3 + 5, size.height - tileHeight - 5);
    }
    if (direction == 1) {
      return Offset(
          size.width - tileWidth - 5, size.height - (tileHeight - 16) * 3 - 16);
    }
    if (direction == 2) {
      return Offset(size.width - tileWidth * 3 - 5, tileHeight + 5);
    }
    if (direction == 3) return Offset(tileWidth + 5, (tileHeight - 16) * 3 + 5);
    assert(false);
    return Offset(0, 0);
  }

  void drawOpenedTilesPerDirection(List<DrawObject> drawObjects,
      tbl.PlayerData data, int direction, Offset originOffset) {
    final baseColPos =
        isPortrait(direction) ? originOffset.dx : originOffset.dy;
    final baseRowPos =
        isPortrait(direction) ? originOffset.dy : originOffset.dx;

    var varColPos = baseColPos;
    void __addDrawObject(int tile) {
      final tileDirection = direction;
      final tileThickness = isPortrait(tileDirection) ? 14 : 16;
      final image = getTileImage(tile, tileDirection);

      final varRowPos = baseRowPos;
      final rowPos = varRowPosToRowPos(direction, image, varRowPos).toDouble();

      if (direction == 1) varColPos += tileThickness;
      final colPos = varColPosToColPos(direction, image, varColPos).toDouble();
      final drawPos = isPortrait(direction)
          ? Offset(colPos, rowPos)
          : Offset(rowPos, colPos);
      drawObjects.add(DrawObject(image, drawPos, false));
      varColPos += stepColPos(direction, image);
      if (direction == 3) varColPos -= tileThickness;
    }

    for (final tile in data.tiles) {
      __addDrawObject(tile);
    }
    for (final tile in data.drawnTile) {
      final image = getTileImage(tile, direction);
      varColPos += stepColPos(direction, image) ~/ 2;
      __addDrawObject(tile);
    }
  }

  void drawDiscardTiles(Canvas canvas, Size size) {
    final drawObjects = <DrawObject>[];

    final keyList = _tableData.playerDataMap.keys.toList();
    final baseDirection = keyList.indexOf(myPeerId);

    for (var direction = 0; direction < 4; direction++) {
      final index = (baseDirection + direction) % 4;
      final data = _tableData.playerDataMap[keyList[index]]!;

      const centerSize = 33 * 3 * 1.0;
      drawDiscardTilesPerDirection(drawObjects, data, direction,
          size.center(centerOffset(direction, centerSize)));
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));
    final normalPaint = Paint();
    final calledTilePaint = Paint();
    calledTilePaint.color = const Color.fromRGBO(0, 0, 0, 0.6);
    for (final item in drawObjects) {
      final paint = item.isCalled ? calledTilePaint : normalPaint;
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
      tbl.PlayerData data, int direction, Offset originOffset) {
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
    // TODO: Rename to drawOpenedTiles
    final drawObjects = <DrawObject>[];

    final keyList = _tableData.playerDataMap.keys.toList();

    final baseDirection = keyList.indexOf(myPeerId);
    for (var direction = 0; direction < 4; direction++) {
      final index = (baseDirection + direction) % 4;
      final peerId = keyList[index];
      final data = _tableData.playerDataMap[peerId]!;
      // print("drawCalledTiles: myPeerId ${myPeerId}, peerId: ${peerId}, direction: ${direction}");

      drawCalledTilesPerDirection(
          drawObjects, peerId, data, direction, offsetForCall(direction, size));
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

  Offset stepForCall(int direction) {
    if (direction == 0) return const Offset(-5, 0);
    if (direction == 1) return const Offset(0, 5);
    if (direction == 2) return const Offset(5, 0);
    if (direction == 3) return const Offset(0, -5);
    assert(false);
    return const Offset(0, 0);
  }

  void drawCalledTilesPerDirection(List<DrawObject> drawObjects, String peerId,
      tbl.PlayerData data, int direction, Offset baseOffset) {
    for (var index = 0; index < data.calledTiles.length; index++) {
      final tiles = data.calledTiles[index];
      baseOffset = drawCalledTilesPerDirection2(
          drawObjects, peerId, tiles, direction, baseOffset, _tableData);
      baseOffset = baseOffset + stepForCall(direction);
    }
  }

  Offset baseOffsetForDrawCalledTiles(int direction, ui.Image image) {
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

  Offset offsetForDrawCalledTiles(
      int direction, ui.Image image, int stepMode, int tileThickness) {
    // return Offset(dx: Col, dy: Row)
    final base = baseOffsetForDrawCalledTiles(direction, image);
    if (stepMode != 2) {
      return base;
    }

    if (direction == 0) {
      return base.translate(0, -image.height.toDouble() + tileThickness);
    }
    if (direction == 1) return base.translate(0, -image.width.toDouble());
    if (direction == 2) {
      return base.translate(0, image.height.toDouble() - tileThickness);
    }
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

  static
  List<List<int>> createCalledTileDirectionMap(
    String peerId,
    tbl.CalledTiles tiles,
    int direction,
    tbl.TableData tableData
  ) {
    final tileDirectionMap = <List<int>>[]; // [direction, tile, step mode]
    if (tiles.callAs == "close-kan") {
      tileDirectionMap.add([direction, -1, 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
      tileDirectionMap.add([direction, -1, 0]);
      return tileDirectionMap;
    }

    //final peerId = _tableData.playerDataMap.keys.toList()[direction];
    final callDirection = tableData.direction(peerId, tiles.calledFrom);
    // print("peerId: ${peerId}, calledFrom: ${tiles.calledFrom}, callDirection: ${callDirection}, direction: ${direction}, callAs: ${tiles.callAs}");
    assert(callDirection != 0);
    final calledTileDirection = (direction + 1) % 4;

    if (tiles.callAs == "pong-chow") {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.insert(
          callDirection - 1, [calledTileDirection, tiles.calledTile, 0]);
    }

    if (tiles.callAs == "open-kan") {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[2], 0]);
      if (callDirection == 3) {
        tileDirectionMap.add([calledTileDirection, tiles.calledTile, 0]);
      } else {
        tileDirectionMap.insert(
            callDirection - 1, [calledTileDirection, tiles.calledTile, 0]);
      }
    }

    if (tiles.callAs == "late-kan") {
      tileDirectionMap.add([direction, tiles.selectedTiles[0], 0]);
      tileDirectionMap.add([direction, tiles.selectedTiles[1], 0]);
      tileDirectionMap.insert(
          callDirection - 1, [calledTileDirection, tiles.calledTile, 1]);
      tileDirectionMap.insert(
          callDirection, [calledTileDirection, tiles.selectedTiles[2], 2]);
    }

    return tileDirectionMap;
  }

  Offset drawCalledTilesPerDirection2(List<DrawObject> drawObjects,
      String peerId, tbl.CalledTiles tiles, int direction, Offset baseOffset,
      tbl.TableData tableData) {
    final tileDirectionMap =
        createCalledTileDirectionMap(peerId, tiles, direction, tableData);
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

      final posOffset =
          offsetForDrawCalledTiles(direction, image, stepMode, tileThickness);
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

  void drawDeadWall(Canvas canvas, Size size) {
    if (_tableData.deadWallTiles.length != 10) {
      return;
    }
    final drawObjects = <DrawObject>[];
    const tileDirection = 0;
    const tileThickness = 14.0;

    final closeTileImage = getTileImage(-1, tileDirection);
    final tileWidth = closeTileImage.width.toDouble();
    final tileHeight = closeTileImage.height.toDouble();

    final baseOffset = size.center(Offset(-tileWidth * 2.5, -tileHeight));

    for (var i = 0; i < 10; i++) {
      final image = (i < 10 - (_tableData.countOfKan + 1))
          ? getTileImage(-1, tileDirection)
          : getTileImage(_tableData.deadWallTiles[i], tileDirection);
      final cols = i % 5;
      final rows = i ~/ 5;
      final drawPos =
          baseOffset.translate(cols * tileWidth, rows * -tileThickness);
      drawObjects.add(DrawObject(image, drawPos, false));
    }

    drawObjects.sort((a, b) => b.pos.dy.compareTo(a.pos.dy));
    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  void drawMyWall(Canvas canvas, Size size, tbl.PlayerData data) {
    final drawObjects = <DrawObject>[];
    const tileDirection = 4;

    final closeTileImage = getTileImage(0, tileDirection);
    final tileWidth = closeTileImage.width.toDouble();
    final tileHeight = closeTileImage.height.toDouble();

    final baseOffset = Offset(tileWidth * 3 + 5, size.height - 5);

    for (var i = 0; i < data.tiles.length; i++) {
      final image = getTileImage(data.tiles[i], 4);
      final drawPos = baseOffset.translate(i * tileWidth, -tileHeight);
      drawObjects.add(DrawObject(image, drawPos, false));
    }

    assert(data.drawnTile.length <= 1);
    for (var i = 0; i < data.drawnTile.length; i++) {
      final image = getTileImage(data.drawnTile[i], tileDirection);
      final drawPos =
          baseOffset.translate(data.tiles.length * tileWidth + 10, -tileHeight);
      drawObjects.add(DrawObject(image, drawPos, false));
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));
    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  ui.Image getTileImage(int tile, direction) {
    // direction = 0: 打牌(上向, 1: 打牌(左向, 2: 打牌(下向, 3: 打牌(右向, 4: 自牌(上向,
    final info = tbl.TileInfo(tile);
    final key = "${info.type}_${info.number}_${direction}";
    final image = _imageMap[key]!;
    return image;
  }

  void drawRiichiBars(Canvas canvas, Size size) {
    final drawObjects = <DrawObject>[];

    final keyList = _tableData.playerDataMap.keys.toList();
    final baseDirection = keyList.indexOf(myPeerId);
    for (var direction = 0; direction < 4; direction++) {
      final index = (baseDirection + direction) % 4;
      final data = _tableData.playerDataMap[keyList[index]]!;
      if (data.riichiTile.isNotEmpty) {
        final drawPos = size.center(riichiBarDrawPos(direction, 33.0 * 2.7));
        final image = _imageMap["riichibar_${direction}"]!;
        drawObjects.add(DrawObject(image, drawPos, false));
      }
    }

    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));
    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  Offset riichiBarDrawPos(int direction, double centerSize) {
    final image = _imageMap["riichibar_${direction}"]!;
    final hW = image.width / 2;
    final hH = image.height / 2;
    late Offset offset;
    if (direction == 0) offset = Offset(0, centerSize);
    if (direction == 1) offset = Offset(centerSize, 0);
    if (direction == 2) offset = Offset(0, -centerSize + hH * 2);
    if (direction == 3) offset = Offset(-centerSize, 0);
    return offset.translate(-hW, -hH);
  }

  void drawStageTile(Canvas canvas, Size size) {
    final drawObjects = <DrawObject>[];

    final keyList = _tableData.playerDataMap.keys.toList();
    final stage = _tableData.leaderChangeCount ~/ 4;
    final baseDirection = keyList.indexOf(myPeerId);
    final firstLeaderDirection = (4 - baseDirection) % 4;

    final image = _imageMap["stage_${stage}_${firstLeaderDirection}"]!;
    final drawPos = stageTileDrawPos(stage, firstLeaderDirection, size);

    drawObjects.add(DrawObject(image, drawPos, false));
    drawObjects.sort((a, b) => a.pos.dy.compareTo(b.pos.dy));
    final paint = Paint();
    for (final item in drawObjects) {
      canvas.drawImage(item.image, item.pos, paint);
    }
  }

  Offset stageTileDrawPos(int stage, int direction, Size size) {
    final image = _imageMap["stage_${stage}_${direction}"]!;
    final hW = image.width / 2;
    final hH = image.height / 2;
    late Offset offset;
    if (direction == 0) offset = Offset(size.width - 100, size.height - 100);
    if (direction == 1) offset = Offset(size.width - 100, 100);
    if (direction == 2) offset = Offset(100, 100);
    if (direction == 3) offset = Offset(100, size.height - 100);
    return offset.translate(-hW, -hH);
  }

  void paint(Canvas canvas, Size size) {
    // print("paint: ${myPeerId}: ${_tableData.toMap()}");
    final myData = _tableData.playerData(myPeerId);
    if (myData == null) return;

    canvas.save();
    const baseTableSize = Size(700, 700); //[px]
    final realTableSize = math.min(size.width, size.height);
    canvas.scale(realTableSize / baseTableSize.width);
    drawDiscardTiles(canvas, baseTableSize);
    drawCalledTiles(canvas, baseTableSize);
    drawDeadWall(canvas, baseTableSize);
    if (myData.openTiles == false) drawMyWall(canvas, baseTableSize, myData);
    drawOpenedTiles(canvas, baseTableSize);
    drawRiichiBars(canvas, baseTableSize);
    drawStageTile(canvas, baseTableSize);
    canvas.restore();
  }
}
