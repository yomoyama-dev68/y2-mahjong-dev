import 'package:flutter/material.dart';
import 'package:y2_mahjong/widgets/tiles_painter.dart';

import '../game_controller.dart' as game;
import '../table_controller.dart' as tbl;

class MyCalledTilesWidget extends StatefulWidget {
  const MyCalledTilesWidget(
      {Key? key, required this.gameData, required this.imageMap})
      : super(key: key);

  final game.Game gameData;
  final Map<String, Image> imageMap;

  @override
  MyCalledTilesWidgetState createState() => MyCalledTilesWidgetState();
}

class MyCalledTilesWidgetState extends State<MyCalledTilesWidget> {
  game.Game g() {
    return widget.gameData;
  }

  @override
  void initState() {
    widget.gameData.onChangeMyTurnTempState = _onChangeMyTurnTempState;
  }

  @override
  Widget build(BuildContext context) {
    return _buildMyCalledTilesList();
  }

  Widget _buildMyCalledTilesList() {
    final myData = g().table.playerData(g().myPeerId)!;
    final widgets = <Widget>[];
    widgets.add(const SizedBox(width: (33 / 0.8) / 2));
    for (var index = myData.calledTiles.length - 1; index >= 0; index--) {
      widgets.add(_buildCalledTiles(index, myData.calledTiles[index]));
      widgets.add(const SizedBox(width: (33 / 0.8) / 2));
    }

    return SingleChildScrollView(
        child: Row(
          children: widgets,
        ),
        scrollDirection: Axis.horizontal);
  }

  Widget _buildCalledTiles(int index, tbl.CalledTiles tiles) {
    List<List<int>> calledTileDirectionMap =
        TilesPainter.createCalledTileDirectionMap(
            g().myPeerId, tiles, 0, g().table);

    const offsetH = (49 - 16.0) / 0.8;
    final widgets = <Widget>[];
    final fromOtherTiles = <Widget>[];
    for (final map in calledTileDirectionMap.reversed) {
      final tile = map[1];
      final tileDirection = map[0];
      if (tileDirection != 0) {
        if (fromOtherTiles.isEmpty) {
          widgets.add(Stack(children: fromOtherTiles));
          fromOtherTiles.add(getTileImage(tile, tileDirection));
        } else {
          fromOtherTiles.insert(
              0,
              Transform.translate(
                  offset: Offset(0, -offsetH),
                  child: getTileImage(tile, tileDirection)));
        }
      } else {
        widgets.add(getTileImage(tile, tileDirection));
      }
    }
    const widgetH = (49 * 2 - 16.0) / 0.8;

    final tappable = (tiles.selectedTiles.length == 2);
    final content = Container(
        color: _isSelected(index) ? Colors.orange : null,
        height: widgetH,
        child: Row(
          children: widgets,
          crossAxisAlignment: CrossAxisAlignment.end,
        ));

    return tappable
        ? GestureDetector(onTap: () => _onTapTile(index), child: content)
        : Opacity(
            opacity: 0.5,
            child: content,
          );
  }

  void _onChangeMyTurnTempState() {
    setState(() {});
  }

  void _onTapTile(int calledTilesIndex) {
    setState(() {
      g().myTurnTempState.selectedCalledTilesIndexForLateKan = calledTilesIndex;
      g().onChangeSelectingTiles?.call();
    });
  }

  bool _isSelected(int index) {
    return index == g().myTurnTempState.selectedCalledTilesIndexForLateKan;
  }

  Image getTileImage(int tile, [direction = 4]) {
    // direction = 0: 打牌(上向, 1: 打牌(左向, 2: 打牌(下向, 3: 打牌(右向, 4: 自牌(上向,
    final info = tbl.TileInfo(tile);
    final key = "${info.type}_${info.number}_${direction}";
    final image = widget.imageMap[key]!;
    return image;
  }
}
