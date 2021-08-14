import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'game_controller.dart' as game;
import 'table_controller.dart' as tbl;

class TableRibbonWidget extends StatefulWidget {
  const TableRibbonWidget({Key? key, required this.gameData}) : super(key: key);

  final game.Game gameData;

  @override
  _TableRibbonWidgetState createState() => _TableRibbonWidgetState();
}

class _TableRibbonWidgetState extends State<TableRibbonWidget> {
  final _selectingTiles = <int>[];

  game.Game g() {
    return widget.gameData;
  }

  bool isMyTurn() {
    return g().myPeerId == g().table.turnedPeerId;
  }

  bool canCmd() {
    return g().canCommand();
  }

  bool isRiichi() {
    // TODO: imple this.
    return false;
  }

  String turnedPlayerName() {
    return g().member[g().table.turnedPeerId] ?? "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    final tblState = g().table.state;
    if (tblState == tbl.TableState.notSetup ||
        tblState == tbl.TableState.doingSetupHand) {
      return const Text("セットアップなう");
    }

    if (tblState == tbl.TableState.drawable) {
      final widgets = isMyTurn()
          ? _buildRibbonForDrawable()
          : _buildRibbonForCallableFromOther();
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: widgets);
    }

    if (tblState == tbl.TableState.waitToDiscard) {
      final cmdWidgets = isMyTurn()
          ? _buildRibbonForWaitingSelfDiscard()
          : _buildRibbonForWaitingOtherDiscard();
      final rowWidgets = <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: cmdWidgets),
      ];
      if (isMyTurn()) rowWidgets.add(_buildMyWall());
      return Column(children: rowWidgets);
    }

    if (tblState == tbl.TableState.processingFinishHand) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _buildRibbonForFinishHand());
    }
    return const Text("エラー：想定していない状態が発生しました。");
  }

  Widget _buildButtonForCallCmd(String text, Function? func) {
    return FloatingActionButton(
        child: Text(text),
        onPressed: canCmd() && (func != null) ? () => func() : null);
  }

  List<Widget> _buildRibbonForFinishHand() {
    return [
      _buildButtonForCallCmd("牌オープン", g().openMyWall),
      _buildButtonForCallCmd("点棒支払", null),
      _buildButtonForCallCmd("次局へ", null),
    ];
  }

  List<Widget> _buildRibbonForDrawable() {
    return [
      _buildButtonForCallCmd("ドロー", g().drawTile),
      _buildButtonForCallCmd("ポン", g().openMyWall),
      _buildButtonForCallCmd("チー", g().startTradingScore),
      _buildButtonForCallCmd("カン", g().drawTile),
      _buildButtonForCallCmd("ロン", g().drawTile)
    ];
  }

  List<Widget> _buildRibbonForCallableFromOther() {
    return [
      _buildButtonForCallCmd("ポン", () {}),
      _buildButtonForCallCmd("カン", () {}),
      _buildButtonForCallCmd("ロン", () {})
    ];
  }

  List<Widget> _buildRibbonForWaitingSelfDiscard() {
    return [
      _buildButtonForCallCmd("カン", () {}),
      _buildButtonForCallCmd("リーチ", () {}),
      _buildButtonForCallCmd("ツモ", () {}),
    ];
  }

  List<Widget> _buildRibbonForWaitingOtherDiscard() {
    return [Text("${turnedPlayerName()}さんの打牌を待っています。")];
  }

  Widget _buildMyWall() {
    final myData = g().table.playerData(g().myPeerId);
    if (myData == null) {
      return const Text("エラー：想定していない状態が発生しました。");
    }

    final widgets = <Widget>[];
    for (final tile in myData.tiles) {
      widgets.add(_buildTile(tile, _selectingTiles.contains(tile)));
    }
    widgets.add(const SizedBox(width: (33 / 0.8) / 2));
    final tile = myData.drawnTile.first;
    widgets.add(_buildTile(tile, _selectingTiles.contains(tile)));

    return SingleChildScrollView(
        child: Row(
          children: widgets,
        ),
        scrollDirection: Axis.horizontal);
  }

  Widget _buildTile(int tile, bool selecting) {
    const scale = 0.8;
    return Container(
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
            : null);
  }

  void _onTapTile(int tile) {
    final tblState = g().table.state;

    setState(() {
      if (tblState == tbl.TableState.waitToDiscard) {
        _selectDiscardTile(tile);
      }
    });
  }

  void _selectDiscardTile(int tile) {
    if (_selectingTiles.isEmpty) {
      _selectingTiles.add(tile);
      return;
    }

    if (_selectingTiles.contains(tile)) {
      _selectingTiles.clear();
      g().discardTile(tile);
    }

    _selectingTiles.clear();
    _selectingTiles.add(tile);
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
