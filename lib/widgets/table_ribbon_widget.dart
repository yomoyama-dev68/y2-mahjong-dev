import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:y2_mahjong/dialogs/notify_dialog.dart';
import 'package:y2_mahjong/dialogs/rollback_dialog.dart';
import 'package:y2_mahjong/dialogs/trading_score_dialog.dart';
import 'package:y2_mahjong/pages/markdown_page.dart';
import 'dart:ui' as ui;

import '../game_controller.dart' as game;
import '../dialogs/leader_continuous_count_dialog.dart';
import '../dialogs/next_hand_dialog.dart';
import '../table_controller.dart' as tbl;

class TableRibbonWidget extends StatefulWidget {
  const TableRibbonWidget(
      {Key? key,
      required this.gameData,
      required this.imageMap,
      required this.showChatDialog})
      : super(key: key);

  final game.Game gameData;
  final Map<String, Image> imageMap;
  final Function showChatDialog;

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
        // print("box1.size: ${box1.size}, "
        //    "pos:${box1.localToGlobal(Offset.zero)}");
      }
      RenderBox? box2 =
          globalKey2.currentContext!.findRenderObject() as RenderBox?;
      if (box2 != null) {
        // print(
        //    "box2.size: ${box2.size}, pos:${box2.localToGlobal(Offset.zero)}");
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
    if (g().isAudience) {
      return _buildForAudience();
    }

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
      _buildButtonForCallCmd("引牌", null),
      _buildButtonForCallCmd("鳴く", null),
      _buildButtonForCallCmd("ロン", null),
    ];
  }

  List<Widget> _buildForAudience() {
    final widgets = <Widget>[];
    for (final player in g().member.entries) {
      widgets.add(_buildButtonForCallCmd(player.value, () {
        // 指定したプレイヤーの視点に切り替える。
        g().setAudienceAs(player.key);
      }));
    }
    return widgets;
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
      if (g().myTurnTempState.selectedCalledTilesIndexForLateKan < 0) {
        return [
          _buildButtonForCallCmd("キャンセル", g().cancelCall),
          _buildButtonForCallCmd("OK", null),
        ];
      } else {
        return [
          _buildButtonForCallCmd("キャンセル", g().cancelCall),
          _buildButtonForCallCmd("OK", g().setSelectedTiles),
        ];
      }
    }
    if (g().selectableTilesQuantity() > 0) {
      final remainTiles = g().selectableTilesQuantity() -
          g().myTurnTempState.selectingTiles.length;
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
        _buildButtonForCallCmd("ポン/チー", g().pongOnChow),
        _buildButtonForCallCmd("カン", g().openKan),
      ];
    }

    if (tblState == tbl.TableState.drawable) {
      if (callable()) {
        return [
          _buildButtonForCallCmd("引牌", g().drawTile),
          _buildButtonForCallCmd("鳴く", g().call),
          _buildButtonForCallCmd("ロン", g().callRon),
        ];
      } else {
        return [
          _buildButtonForCallCmd("引牌", g().drawTile),
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
        _buildButtonForCallCmd("暗槓", g().closeKan),
        _buildButtonForCallCmd("加槓", g().lateKan),
        _buildButtonForCallCmd("ツモ", g().tsumo),
      ];
    }

    if (tblState == tbl.TableState.waitToDiscardForPongOrChow) {
      return [
        _buildButtonForCallCmd("リーチ", null),
        _buildButtonForCallCmd("暗槓", null),
        _buildButtonForCallCmd("加槓", null),
        _buildButtonForCallCmd("ツモ", null),
      ];
    }

    return [];
  }

  List<Widget> buildForOtherTurn() {
    if (callable()) {
      return [
        _buildButtonForCallCmd("引牌", null),
        _buildButtonForCallCmd("鳴く", g().call),
        _buildButtonForCallCmd("ロン", g().callRon),
      ];
    }
    return [
      _buildButtonForCallCmd("引牌", null),
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
    final rollbackable = [
      tbl.TableState.drawable,
      tbl.TableState.processingFinishHand
    ].contains(g().table.state);
    final isPlayer = g().member.keys.contains(g().myPeerId);

    final menus = <PopupMenuEntry<String>>[];
    if (isPlayer) {
      menus
        ..add(const PopupMenuItem<String>(
          value: "openMyWall",
          child: Text("手牌オープン"),
        ))
        ..add(const PopupMenuItem<String>(
          value: "startTradingScore",
          child: Text('点棒支払'),
        ))
        ..add(const PopupMenuItem<String>(
          value: "changeLeaderContinuousCount",
          child: Text('場数変更'),
        ))
        ..add(PopupMenuItem<String>(
          value: "drawGame",
          child: const Text('流局'),
          enabled: enabledDrawGame,
        ))
        ..add(PopupMenuItem<String>(
          value: "rollback",
          child: const Text('巻き戻し'),
          enabled: rollbackable,
        ));
    }
    menus
      ..add(PopupMenuItem<String>(
        value: g().enabledAudio ? "mute" : "mute-off",
        child: Text(g().enabledAudio ? "ミュート" : "ミュートオフ"),
        enabled: g().availableAudio,
      ))
      ..add(const PopupMenuItem<String>(
        value: "chat",
        child: Text('チャット'),
      ))
      ..add(const PopupMenuItem<String>(
        value: "licenses",
        child: Text("ライセンス"),
      ));

    return PopupMenuButton<String>(
        onSelected: _onSelectedPopupMenu,
        itemBuilder: (BuildContext context) => menus);
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
    if (menu == "rollback") {
      showRollbackDialog(context, g(), widget.imageMap).then((index) {
        if (index != null) {
          g().handleRequestRollback(index);
        }
      });
    }
    if (menu == "mute-off") {
      g().setEnabledAudio(true);
    }
    if (menu == "mute") {
      g().setEnabledAudio(false);
    }
    if (menu == "chat") {
      widget.showChatDialog();
    }
    if (menu == "licenses") {
      rootBundle.loadString('assets/licenses.md').then((text) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return MarkDownPage(markdownText: text);
            },
          ),
        );
      });
    }
  }
}
