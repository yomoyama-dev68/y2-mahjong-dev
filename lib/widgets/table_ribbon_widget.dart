import 'package:flutter/material.dart';
import 'package:web_app_sample/dialogs/trading_score_dialog.dart';
import 'dart:ui' as ui;

import '../game_controller.dart' as game;
import '../dialogs/leader_continuous_count_dialog.dart';
import '../dialogs/next_hand_dialog.dart';
import '../table_controller.dart' as tbl;

class TableRibbonWidget extends StatefulWidget {
  const TableRibbonWidget({Key? key, required this.gameData}) : super(key: key);

  final game.Game gameData;

  @override
  _TableRibbonWidgetState createState() => _TableRibbonWidgetState();
}

class _TableRibbonWidgetState extends State<TableRibbonWidget> {
  var globalKey1 = GlobalKey();
  var globalKey2 = GlobalKey();
  var globalKey3 = GlobalKey();

  game.Game g() {
    return widget.gameData;
  }

  bool canCmd() {
    // print ("canCmd: ${g().myPeerId}: ${g().canCommand()}");
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

  var lastScrollViewSize = 100.0;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((cb) {
      RenderBox? box1 =
          globalKey1.currentContext!.findRenderObject() as RenderBox?;
      if (box1 != null) {
        print(
            "box1.size: ${box1.size}, pos:${box1.localToGlobal(Offset.zero)}");
      }
      RenderBox? box2 =
          globalKey2.currentContext!.findRenderObject() as RenderBox?;
      if (box2 != null) {
        print(
            "box2.size: ${box2.size}, pos:${box2.localToGlobal(Offset.zero)}");
        if (lastScrollViewSize != box2.size.width - 20) {
          setState(() {
            lastScrollViewSize = box2.size.width - 20;
          });
        }
      }
    });

    return Row(children: [
      Expanded(
          key: globalKey2,
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: lastScrollViewSize,
                  ),
                  child: Row(
                    key: globalKey1,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: buildActionButtons(),
                  )))),
      Container(child: _buildPopupMenu())
    ]);
  }

  List<Widget> buildActionButtons() {
    final tblState = g().table.state;

    if (tblState == tbl.TableState.notSetup ||
        tblState == tbl.TableState.doingSetupHand) {
      return _buildInSetup();
    }

    if (tblState == tbl.TableState.processingFinishHand) {
      return _buildRibbonForFinishHand();
    }

    if (g().isMyTurn()) {
      return _buildForMyTurn();
    } else {
      return buildForOtherTurn();
    }
  }

  Widget _buildButtonForCallCmd(String text, Function? func) {
    return ElevatedButton(
        child: Text(text),
        onPressed: canCmd() && (func != null)
            ? () {
                func();
                setState(() {});
              }
            : null);
  }

  List<Widget> _buildInSetup() {
    return [
      _buildButtonForCallCmd("ツモる", null),
      _buildButtonForCallCmd("鳴く", null),
      _buildButtonForCallCmd("ロン", null),
    ];
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
      final remainTiles = g().selectableTilesQuantity() - g().myTurnTempState.selectingTiles.length;
      if (remainTiles == 0) {
        return [
          _buildButtonForCallCmd("キャンセル", g().cancelCall),
          _buildButtonForCallCmd("OK", g().setSelectedTiles),
        ];
      } else {
        return [
          _buildButtonForCallCmd("キャンセル", g().cancelCall),
          _buildButtonForCallCmd("残り${remainTiles}牌", null),
        ];
      }
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
        _buildButtonForCallCmd("ロン", g().callRon),
      ];
    }
    return [
      _buildButtonForCallCmd("ツモる", null),
      _buildButtonForCallCmd("鳴く", null),
      _buildButtonForCallCmd("ロン", null),
    ];
  }

  List<Widget> _buildRibbonForFinishHand() {
    return [
      _buildButtonForCallCmd("手牌オープン", g().openMyWall),
      _buildButtonForCallCmd("点棒支払", () {
        showTradingScoreRequestDialog(context, g());
      }),
      _buildButtonForCallCmd("次局へ", () {
        showRequestNextHandDialog(context, g());
      }),
      _buildButtonForCallCmd("ゲームリセット", g().requestGameReset),
    ];
  }

  Widget _buildPopupMenu() {
    final enabledDrawGame = g().table.state == tbl.TableState.drawable;
    return PopupMenuButton<String>(
      onSelected: _onSelectedPopupMenu,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: "openMyWall",
          child: Text("手牌オープン"),
        ),
        const PopupMenuItem<String>(
          value: "startTradingScore",
          child: Text('点棒支払'),
        ),
        const PopupMenuItem<String>(
          value: "changeLeaderContinuousCount",
          child: Text('場数変更'),
        ),
        PopupMenuItem<String>(
          value: "drawGame",
          child: const Text('流局'),
          enabled: enabledDrawGame,
        ),
      ],
    );
  }

  void _onSelectedPopupMenu(String menu) {
    if (menu == "openMyWall") g().openMyWall();
    if (menu == "startTradingScore") {
      showTradingScoreRequestDialog(context, g());
    }
    if (menu == "changeLeaderContinuousCount") {
      showChangeLeaderContinuousCountDialog(context, g());
    }
    if (menu == "drawGame") g().requestDrawGame();
  }
}
