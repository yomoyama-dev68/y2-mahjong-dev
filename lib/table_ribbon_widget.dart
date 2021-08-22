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

  String turnedPlayerName() {
    return g().member[g().table.turnedPeerId] ?? "Unknown";
  }

  List<Widget> buildForMyTurn() {
    if (g().handLocalState.onCalledTsumo) {
      return [
        _buildButtonForCallCmd("Ok", g().finishHand),
        _buildButtonForCallCmd("Cancel", g().cancelTsumo),
      ];
    }

    final tblState = g().table.state;
    if (tblState == tbl.TableState.drawable) {
      return _buildRibbonForDrawable();
    }
    if (tblState == tbl.TableState.waitToDiscard) {
      return _buildRibbonForWaitingSelfDiscard();
    }

    const selectingTiles = [
      tbl.TableState.selectingTilesForPong,
      tbl.TableState.selectingTilesForChow,
      tbl.TableState.selectingTilesForOpenKan,
      tbl.TableState.selectingTilesForCloseKan,
      tbl.TableState.selectingTilesForLateKan,
    ];
    if (selectingTiles.contains(tblState)) {
      return _buildRibbonForSelectingTiles();
    }

    if (tblState == tbl.TableState.selectingCloseOrLateKan) {
      return _buildRibbonForSelectingCloseOrLateKan();
    }

    if (tblState == tbl.TableState.calledRon) {
      return _buildRibbonForConfirmingAboutFinishHand();
    }

    return [];
  }

  List<Widget> buildForOtherTurn() {
    final tblState = g().table.state;
    if (tblState == tbl.TableState.drawable) {
      return _buildRibbonForCallableFromOther();
    }
    if (g().table.isSelectingTileState()) {
      return _buildRibbonForWaitingOtherDiscard();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final tblState = g().table.state;

    if (tblState == tbl.TableState.notSetup ||
        tblState == tbl.TableState.doingSetupHand) {
      return const Text("セットアップなう");
    }
    if (tblState == tbl.TableState.processingFinishHand) {
      if (isWaitingNextHand()) {
        return Text("次局の開始を待っています。");
      } else {
        return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildRibbonForFinishHand());
      }
    }

    if (isMyTurn()) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: buildForMyTurn());
    } else {
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: buildForOtherTurn());
    }
  }

  Widget _buildButtonForCallCmd(String text, Function? func) {
    return ElevatedButton(
        child: Text(text),
        onPressed: canCmd() && (func != null) ? () => func() : null);
  }

  List<Widget> _buildRibbonForDrawable() {
    return [
      _buildButtonForCallCmd("ドロー", g().drawTile),
      _buildButtonForCallCmd("ポン", g().pong),
      _buildButtonForCallCmd("チー", g().chow),
      _buildButtonForCallCmd("カン", g().openKan),
      _buildPopupMenu(),
    ];
  }

  List<Widget> _buildRibbonForWaitingSelfDiscard() {
    if (g().handLocalState.onCalledRiichi) {
      return [
        _buildButtonForCallCmd("キャンセルリーチ", g().cancelRiichi),
      ];
    } else {
      return [
        _buildButtonForCallCmd("カン", g().selfKan),
        _buildButtonForCallCmd("リーチ", g().riichi),
        _buildButtonForCallCmd("ツモ", g().tsumo),
      ];
    }
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
      _buildButtonForCallCmd("キャンセル", g().cancelCall),
      _buildButtonForCallCmd("OK", g().setSelectedTiles),
    ];
  }

  List<Widget> _buildRibbonForConfirmingAboutFinishHand() {
    return [
      _buildButtonForCallCmd("キャンセル", g().cancelCall),
      _buildButtonForCallCmd("Ok", g().finishHand),
    ];
  }

  List<Widget> _buildRibbonForCallableFromOther() {
    return [
      _buildButtonForCallCmd("ポン", g().pong),
      _buildButtonForCallCmd("カン", g().openKan),
      _buildButtonForCallCmd("ロン", g().ron)
    ];
  }

  List<Widget> _buildRibbonForWaitingOtherDiscard() {
    return [Text("${turnedPlayerName()}さんの打牌を待っています。")];
  }

  List<Widget> _buildRibbonForFinishHand() {
    return [
      _buildButtonForCallCmd("牌オープン", g().openMyWall),
      _buildButtonForCallCmd("点棒支払", g().startTradingScore),
      _buildButtonForCallCmd("次局へ", g().requestNextHand),
    ];
  }

  void _onSelectedPopupMenu(String menu) {
    if (menu == "openMyWall") g().openMyWall();
    if (menu == "startTradingScore") g().startTradingScore();
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: _onSelectedPopupMenu,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: "openMyWall",
          child: Text("牌オープン"),
        ),
        const PopupMenuItem<String>(
          value: "startTradingScore",
          child: Text('点棒支払'),
        ),
      ],
    );
  }
}
