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
      required this.tappableTileScale,
      required this.showChatDialog})
      : super(key: key);

  final game.Game gameData;
  final Map<String, Image> imageMap;
  final double tableSize;
  final double tappableTileScale;
  final Function showChatDialog;

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
    final widgets = <Widget>[];
    if (!g().isAudience) {
      widgets.add(
        SizedBox(
            width: widget.tableSize,
            height: widgetH,
            child: Center(child: _buildTilesWidget())),
      );
    }
    widgets.add(SizedBox(
      width: widget.tableSize,
      child: TableRibbonWidget(
        gameData: g(),
        imageMap: widget.imageMap,
        showChatDialog: widget.showChatDialog,
      ),
    ));

    return Column(children: widgets);
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
