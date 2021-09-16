import 'package:flutter/material.dart';

import '../game_controller.dart' as game;
import 'called_tiles_widget.dart';
import 'table_ribbon_widget.dart';
import 'mywall_widget.dart';

class ActionsBarWidget extends StatefulWidget {
  const ActionsBarWidget(
      {Key? key,
      required this.gameData,
      required this.imageMap,
      required this.tableSize,
      required this.tappableTileScale})
      : super(key: key);

  final game.Game gameData;
  final Map<String, Image> imageMap;
  final double tableSize;
  final double tappableTileScale;

  @override
  ActionsBarWidgetState createState() => ActionsBarWidgetState();
}

class ActionsBarWidgetState extends State<ActionsBarWidget> {
  game.Game g() {
    return widget.gameData;
  }

  @override
  void initState() {
    super.initState();
    widget.gameData.onChangeSelectingTiles = _onChangeSelectingTiles;
  }

  @override
  Widget build(BuildContext context) {
    final widgetH = (49 * 2 - 16.0) / widget.tappableTileScale;
    return Column(children: [
      SizedBox(
          width: widget.tableSize, height: widgetH, child: _buildTilesWidget()),
      SizedBox(
        width: widget.tableSize,
        child: TableRibbonWidget(gameData: g()),
      )
    ]);
  }

  Widget _buildTilesWidget() {
    if (g().myTurnTempState.onCalledFor == "lateKanStep2") {
      return MyCalledTilesWidget(
        gameData: g(),
        imageMap: widget.imageMap,
      );
    } else {
      return MyWallWidget(
        gameData: g(),
        imageMap: widget.imageMap,
      );
    }
  }

  void _onChangeSelectingTiles() {
    setState(() {});
  }
}
