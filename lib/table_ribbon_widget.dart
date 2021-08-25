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

    if (g().isMyTurn()) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _buildForMyTurn());
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

  List<Widget> _buildForMyTurn() {
    if (g().handLocalState.onCalledTsumo) {
      return [
        _buildButtonForCallCmd("キャンセル", g().cancelTsumo),
        _buildButtonForCallCmd("Ok", g().win),
      ];
    }
    if (g().handLocalState.onCalledRon) {
      return [
        _buildButtonForCallCmd("キャンセル", g().cancelCall),
        _buildButtonForCallCmd("Ok", g().win),
      ];
    }
    if (g().handLocalState.onCalledRiichi) {
      return [
        _buildButtonForCallCmd("リーチキャンセル", g().cancelRiichi),
      ];
    }
    if (g().selectableTilesQuantity() > 0) {
      return [
        _buildButtonForCallCmd("キャンセル", g().cancelCall),
        _buildButtonForCallCmd("OK", g().setSelectedTiles),
      ];
    }

    final tblState = g().table.state;
    if (tblState == tbl.TableState.called) {
      return [
        _buildButtonForCallCmd("キャンセル", g().cancelCall),
        _buildButtonForCallCmd("ポン", g().pong),
        _buildButtonForCallCmd("チー", g().chow),
        _buildButtonForCallCmd("カン", g().openKan),
      ];
    }

    if (tblState == tbl.TableState.drawable) {
      return [
        _buildButtonForCallCmd("ツモる", g().drawTile),
        _buildButtonForCallCmd("鳴く", g().call),
        _buildButtonForCallCmd("ロン", g().callRon),
      ];
    }

    if ([
      tbl.TableState.waitToDiscard,
      tbl.TableState.waitToDiscardForOpenOrLateKan,
      tbl.TableState.waitToDiscardForPongOrChow
    ].contains(tblState)) {
      return [
        _buildButtonForCallCmd("リーチ", g().riichi),
        _buildButtonForCallCmd("ツモ", g().tsumo),
        _buildButtonForCallCmd("暗槓", g().closeKan),
        _buildButtonForCallCmd("加槓", g().lateKan),
      ];
    }

    return [];
  }

  List<Widget> buildForOtherTurn() {
    final tblState = g().table.state;
    if (tblState == tbl.TableState.drawable) {
      return [
        _buildButtonForCallCmd("鳴く", g().call),
        _buildButtonForCallCmd("ロン", g().callRon)
      ];
    }
    return [
      _buildButtonForCallCmd("鳴く", null),
      _buildButtonForCallCmd("ロン", null)
    ];
  }

  List<Widget> _buildRibbonForFinishHand() {
    return [
      _buildButtonForCallCmd("牌オープン", g().openMyWall),
      _buildButtonForCallCmd("点棒支払", g().startTradingScore),
      _buildButtonForCallCmd("次局へ", g().requestNextHand),
    ];
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

  void _onSelectedPopupMenu(String menu) {
    if (menu == "openMyWall") g().openMyWall();
    if (menu == "startTradingScore") g().startTradingScore();
  }
}
