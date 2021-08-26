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

  bool callable() {
    if (g().table.state != tbl.TableState.drawable) {
      return false;
    }
    if (g().table.lastDiscardedTile < 0) {
      // 最初の捨て牌がない場合。
      return false;
    }
    if (g().table.lastDiscardedPlayerPeerID == g().myPeerId) {
      // 最後に捨てたのが自分の場合。
      return false;
    }
    return true;
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
    if (g().myTurnTempState.onCalledRiichi) {
      return [
        _buildButtonForCallCmd("リーチキャンセル", g().cancelRiichi),
      ];
    }
    if (g().myTurnTempState.onCalledTsumo) {
      return [
        _buildButtonForCallCmd("キャンセル", g().cancelTsumo),
        _buildButtonForCallCmd("Ok", g().win),
      ];
    }
    if (g().myTurnTempState.onCalledRon) {
      return [
        _buildButtonForCallCmd("キャンセル", g().cancelCall),
        _buildButtonForCallCmd("Ok", g().win),
      ];
    }
    if (g().myTurnTempState.onCalledFor == "lateKanStep2") {
      return [
        _buildButtonForCallCmd("キャンセル", g().cancelCall),
        _buildButtonForCallCmd("OK", g().setSelectedTiles),
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
      if (callable()) {
        return [
          _buildButtonForCallCmd("ツモる", g().drawTile),
          _buildButtonForCallCmd("鳴く", g().call),
          _buildButtonForCallCmd("ロン", g().callRon),
        ];
      } else {
        return [
          _buildButtonForCallCmd("ツモる", g().drawTile),
          _buildButtonForCallCmd("鳴く", null),
          _buildButtonForCallCmd("ロン", null),
        ];
      }
    }

    if ([
      tbl.TableState.waitToDiscard,
      tbl.TableState.waitToDiscardForOpenOrLateKan,
    ].contains(tblState)) {
      return [
        _buildButtonForCallCmd("リーチ", g().riichi),
        _buildButtonForCallCmd("ツモ", g().tsumo),
        _buildButtonForCallCmd("暗槓", g().closeKan),
        _buildButtonForCallCmd("加槓", g().lateKan),
      ];
    }

    if (tblState == tbl.TableState.waitToDiscardForPongOrChow) {
      return [
        _buildButtonForCallCmd("リーチ", null),
        _buildButtonForCallCmd("ツモ", null),
        _buildButtonForCallCmd("暗槓", null),
        _buildButtonForCallCmd("加槓", null),
      ];
    }


    return [];
  }

  List<Widget> buildForOtherTurn() {
    if (callable()) {
      return [
        _buildButtonForCallCmd("ツモる", null),
        _buildButtonForCallCmd("鳴く", g().call),
        _buildButtonForCallCmd("ロン", g().callRon)
      ];
    }
    return [
      _buildButtonForCallCmd("ツモる", null),
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
