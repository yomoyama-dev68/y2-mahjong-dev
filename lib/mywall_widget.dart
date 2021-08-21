import 'package:flutter/material.dart';

import 'game_controller.dart' as game;
import 'table_controller.dart' as tbl;

class MyWallWidget extends StatefulWidget {
  const MyWallWidget({Key? key, required this.gameData}) : super(key: key);

  final game.Game gameData;

  @override
  MyWallWidgetState createState() => MyWallWidgetState();
}

class MyWallWidgetState extends State<MyWallWidget> {
  game.Game g() {
    return widget.gameData;
  }

  @override
  Widget build(BuildContext context) {
    return _buildMyWall();
  }

  Widget _buildMyWall() {
    final selectingTiles = g().handLocalState.selectingTiles;
    final myData = g().table.playerData(g().myPeerId)!;
    final widgets = <Widget>[];
    for (final tile in myData.tiles) {
      widgets.add(_buildTile(tile, selectingTiles.contains(tile)));
    }
    if (myData.drawnTile.isNotEmpty) {
      widgets.add(const SizedBox(width: (33 / 0.8) / 2));
      final tile = myData.drawnTile.first;
      widgets.add(_buildTile(tile, selectingTiles.contains(tile)));
    }

    return SingleChildScrollView(
        child: Row(
          children: widgets,
        ),
        scrollDirection: Axis.horizontal);
  }

  Widget _buildTile(int tile, bool selecting) {
    const scale = 0.8;
    return Material(
        child: Container(
            child: Ink.image(
              image: Image.asset(_tileToImageFileUrl(tile), scale: scale).image,
              height: 59.0 / scale,
              width: 33.0 / scale,
              child: InkWell(
                onTap: () => _onTapTile(tile),
                child: const SizedBox(),
              ),
            ),
            decoration: selecting
                ? BoxDecoration(
                    border: Border.all(color: Colors.red),
                  )
                : null));
  }

  void _onTapTile(int tile) {
    setState(() {
      final tblState = g().table.state;
      const waitToDiscard = [
        tbl.TableState.waitToDiscard,
        tbl.TableState.waitToDiscardForPongOrChow,
        tbl.TableState.waitToDiscardForOpenKan,
        tbl.TableState.waitToDiscardForCloseKan,
        tbl.TableState.waitToDiscardForLateKan
      ];
      if (waitToDiscard.contains(tblState)) {
        _selectDiscardTile(tile);
      }
      int limit = _selectableTilesQuantity(tblState);
      if (limit > 0) _selectTile(tile, limit);
    });
  }

  void _selectDiscardTile(int tile) {
    final selectingTiles = g().handLocalState.selectingTiles;
    if (selectingTiles.isEmpty) {
      selectingTiles.add(tile);
    } else if (selectingTiles.contains(tile)) {
      g().discardTile(tile);
    } else {
      selectingTiles.clear();
      selectingTiles.add(tile);
    }
  }

  int _selectableTilesQuantity(String tblState) {
    if (tblState == tbl.TableState.selectingTilesForPong) return 2;
    if (tblState == tbl.TableState.selectingTilesForChow) return 2;
    if (tblState == tbl.TableState.selectingTilesForOpenKan) return 3;
    if (tblState == tbl.TableState.selectingTilesForCloseKan) return 4;
    if (tblState == tbl.TableState.selectingTilesForLateKan) return 1;
    return 0;
  }

  void _selectTile(int tile, limit) {
    final selectingTiles = g().handLocalState.selectingTiles;
    if (selectingTiles.contains(tile)) {
      selectingTiles.remove(tile);
    } else {
      if (selectingTiles.length < limit) {
        selectingTiles.add(tile);
      }
    }
  }

  String _tileToImageFileUrl(int tile) {
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
}
