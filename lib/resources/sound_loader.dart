import 'dart:async';

import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

class Sounds {
  static final _pool = Soundpool.fromOptions();
  static final _discardTile =
      rootBundle.load("assets/sounds/discard_tile.wav").then((ByteData data) {
    return _pool.load(data);
  });
  static final _drawTile =
      rootBundle.load("assets/sounds/draw_tile.wav").then((ByteData data) {
    return _pool.load(data);
  });
  static final _sortTiles =
      rootBundle.load("assets/sounds/sort_tiles.wav").then((ByteData data) {
    return _pool.load(data);
  });
  static final _openMyWall =
      rootBundle.load("assets/sounds/open_my_wall.wav").then((ByteData data) {
    return _pool.load(data);
  });

  static discardTile() async {
    _pool.play(await _discardTile);
  }

  static drawTile() async {
    _pool.play(await _drawTile);
  }

  static sortTiles() async {
    _pool.play(await _sortTiles);
  }

  static openMyWall() async {
    _pool.play(await _openMyWall);
  }
}
