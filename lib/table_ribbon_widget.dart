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

  bool isWaitingNextHand() {
    final myData = g().table.playerDataMap[g().myPeerId];
    if (myData == null) return false;
    return myData.waitingNextHand;
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
    print("build: " + tblState);

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

    const waitToDiscardForCall = [
      tbl.TableState.waitToDiscardForPongOrChow,
      tbl.TableState.waitToDiscardForOpenKan,
      tbl.TableState.waitToDiscardForCloseKan,
      tbl.TableState.waitToDiscardForLateKan
    ];
    if (waitToDiscardForCall.contains(tblState)) {
      final cmdWidgets =
          isMyTurn() ? [_buildMyWall()] : _buildRibbonForWaitingOtherDiscard();
      return Column(children: cmdWidgets);
    }

    const selectingTiles = [
      tbl.TableState.selectingTilesForPong,
      tbl.TableState.selectingTilesForChow,
      tbl.TableState.selectingTilesForOpenKan,
      tbl.TableState.selectingTilesForCloseKan,
      tbl.TableState.selectingTilesForLateKan,
    ];

    if (selectingTiles.contains(tblState)) {
      final cmdWidgets = isMyTurn()
          ? _buildRibbonForSelectingTiles()
          : _buildRibbonForWaitingOtherDiscard();
      final rowWidgets = <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: cmdWidgets),
      ];
      if (isMyTurn()) rowWidgets.add(_buildMyWall());
      return Column(children: rowWidgets);
    }

    if (tblState == tbl.TableState.selectingCloseOrLateKan) {
      final cmdWidgets = isMyTurn()
          ? _buildRibbonForSelectingCloseOrLateKan()
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
      final cmdWidgets = isWaitingNextHand()
          ? [Text("次局の開始を待っています。")]
          : _buildRibbonForFinishHand();
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: cmdWidgets);
    }

    if (tblState == tbl.TableState.calledRon) {
      final cmdWidgets = isMyTurn()
          ? _buildRibbonForConfirmingAboutFinishHand()
          : [Text("${turnedPlayerName()}さんがロンしました。")];
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: cmdWidgets);
    }

    return const Text("エラー：想定していない状態が発生しました。");
  }

  Widget _buildButtonForCallCmd(String text, Function? func) {
    return FloatingActionButton(
        child: Text(text),
        onPressed: canCmd() && (func != null) ? () => func() : null);
  }

  List<Widget> _buildRibbonForConfirmingAboutFinishHand() {
    return [
      _buildButtonForCallCmd("Ok", g().finishHand),
      _buildButtonForCallCmd("Cancel", g().cancelCall),
    ];
  }

  List<Widget> _buildRibbonForFinishHand() {
    return [
      _buildButtonForCallCmd("牌オープン", g().openMyWall),
      _buildButtonForCallCmd("点棒支払", g().startTradingScore),
      _buildButtonForCallCmd("次局へ", g().requestNextHand),
    ];
  }

  List<Widget> _buildRibbonForDrawable() {
    return [
      _buildButtonForCallCmd("ドロー", g().drawTile),
      _buildButtonForCallCmd("ポン", g().pong),
      _buildButtonForCallCmd("チー", g().chow),
      _buildButtonForCallCmd("カン", g().openKan),
    ];
  }

  List<Widget> _buildRibbonForCallableFromOther() {
    return [
      _buildButtonForCallCmd("ポン", g().pong),
      _buildButtonForCallCmd("カン", g().openKan),
      _buildButtonForCallCmd("ロン", g().ron)
    ];
  }

  List<Widget> _buildRibbonForWaitingSelfDiscard() {
    return [
      _buildButtonForCallCmd("カン", g().selfKan),
      _buildButtonForCallCmd("リーチ", () {}),
      _buildButtonForCallCmd("ツモ", () {}),
    ];
  }

  List<Widget> _buildRibbonForSelectingCloseOrLateKan() {
    return [
      _buildButtonForCallCmd("キャンセル", g().cancelCall),
      _buildButtonForCallCmd("暗カン", g().closeKan),
      _buildButtonForCallCmd("加カン", g().lateKan),
    ];
  }

  List<Widget> _buildRibbonForSelectingTiles() {
    return [
      _buildButtonForCallCmd("キャンセル", () {
        g().cancelCall();
        _selectingTiles.clear();
      }),
      _buildButtonForCallCmd("OK", () {
        print("OK");
        g().setSelectedTiles([..._selectingTiles]);
        _selectingTiles.clear();
      }),
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
    if (myData.drawnTile.isNotEmpty) {
      widgets.add(const SizedBox(width: (33 / 0.8) / 2));
      final tile = myData.drawnTile.first;
      widgets.add(_buildTile(tile, _selectingTiles.contains(tile)));
    }

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
    print("_onTapTile E: ${tblState}: ${_selectingTiles}");

    setState(() {
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

    print("_onTapTile X: ${tblState}: ${_selectingTiles}");
  }

  void _selectDiscardTile(int tile) {
    if (_selectingTiles.isEmpty) {
      _selectingTiles.add(tile);
    } else if (_selectingTiles.contains(tile)) {
      g().discardTile(tile);
      _selectingTiles.clear();
    } else {
      _selectingTiles.clear();
      _selectingTiles.add(tile);
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
    if (_selectingTiles.contains(tile)) {
      _selectingTiles.remove(tile);
    } else {
      if (_selectingTiles.length < limit) {
        _selectingTiles.add(tile);
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
