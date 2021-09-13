import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:meta/meta.dart';

import '../game_controller.dart' as game;

void showTradingScoreAcceptDialog(
    BuildContext context, game.Game gameData, String requester, int score) {
  final content = TradingScoreAcceptWidget(
    gameData: gameData,
    requester: requester,
    score: score,
  );
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('点棒支払を受け入れますか？'),
          content: content,
          actions: <Widget>[
            SimpleDialogOption(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              child: Text('OK'),
              onPressed: () {
                content.doAccept();
                Navigator.pop(context);
              },
            ),
          ],
        );
      });
}

class TradingScoreAcceptWidget extends StatelessWidget {
  const TradingScoreAcceptWidget(
      {Key? key,
      required this.gameData,
      required this.requester,
      required this.score})
      : super(key: key);

  final game.Game gameData;
  final String requester;
  final int score;

  void doAccept() {
    gameData.acceptRequestedScore(requester, score);
  }

  @override
  Widget build(BuildContext context) {
    final name = gameData.member[requester];
    final textController = TextEditingController();
    textController.text = score.toString();

    return TextField(
      controller: textController,
      readOnly: true,
      decoration: InputDecoration(
          labelText: "${name}から", border: const OutlineInputBorder()),
    );
  }
}

void showTradingScoreRequestDialog(BuildContext context, game.Game gameData) {
  final content = TradingScoreRequestWidget(gameData: gameData);
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('点棒支払'),
          content: content,
          actions: <Widget>[
            SimpleDialogOption(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              child: Text('OK'),
              onPressed: () {
                content.state.first.doRequest();
                Navigator.pop(context);
              },
            ),
          ],
        );
      });
}


class TradingScoreRequestWidget extends StatefulWidget {
  TradingScoreRequestWidget({Key? key, required this.gameData})
      : super(key: key);

  final game.Game gameData;
  final state = <TradingScoreRequestWidgetState>[];

  @override
  State<StatefulWidget> createState() => TradingScoreRequestWidgetState();
}

class TradingScoreRequestWidgetState extends State<TradingScoreRequestWidget> {
  final textControllerMap = <String, TextEditingController>{};
  final keyMap = <String, GlobalKey>{};
  final focusMap = <String, FocusNode>{};
  //final scrollController = ScrollController();

  void _onFocusChange(String peerId) async {
    print("_onFocusChange: focus.offset=${focusMap[peerId]!.offset}");

    // Find the object which has the focus
    final key = keyMap[peerId]!;
    final object = key.currentContext!.findRenderObject()!;
    final viewport = RenderAbstractViewport.of(object);
    await Future.delayed(const Duration(milliseconds: 400));
    if (viewport == null) {
      return;
    }
    print("viewport.getOffsetToReveal(object, 0.0).offset = ${viewport.getOffsetToReveal(object, 0.0).offset}");
    print("viewport.getOffsetToReveal(object, 1.0).offset = ${viewport.getOffsetToReveal(object, 1.0).offset}");

    ScrollableState? scrollableState = Scrollable.of(key.currentContext!);
    assert(scrollableState != null);

    print("scrollableState!.position=${scrollableState!.position}");
    ScrollPosition position = scrollableState.position;
    double alignment;
    if (position.pixels > viewport.getOffsetToReveal(object, 0.0).offset) {
      alignment = 0.0;
    } else if (position.pixels < viewport.getOffsetToReveal(object, 1.0).offset){
      alignment = 1.0;
    } else {
      return;
    }

    position.ensureVisible(
      object,
      alignment: alignment,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  game.Game g() {
    return widget.gameData;
  }

  @override
  void initState() {
    widget.state.add(this);
  }

  void doRequest() {
    final request = textControllerMap
        .map((key, value) => MapEntry(key, int.tryParse(value.text) ?? 0));
    request.removeWhere((key, value) => value == 0);
    g().requestScore(request);
  }

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    final dummyMembers = {
      "AAA": "AAA",
      "BBB": "BBB",
      "CCC": "CCC",
      "DDD": "DDD",
      "EEE": "EEE",
      "FFF": "FFF",
      "GGG": "GGG",
      "HHH": "HHH",
    };
    for (final e in g().member.entries) {
    //for (final e in dummyMembers.entries) {
      final textController = TextEditingController();
      if (g().myPeerId == e.key) continue;
      textControllerMap[e.key] = textController;
      final globalKey = GlobalKey();
      keyMap[e.key] = globalKey;
      final focus = FocusNode();
      focusMap[e.key] = focus;
      focus.addListener(() {
        _onFocusChange(e.key);
      });

      widgets.add(TextField(
        key: globalKey,
        controller: textController,
        decoration: InputDecoration(
            labelText: "${e.value}へ", border: OutlineInputBorder()),
        autofocus: false,
        keyboardType: TextInputType.number,
        focusNode: focus,
      ));
      widgets.add(const SizedBox(
        height: 10,
      ));
    }

    return SingleChildScrollView(
//      controller: scrollController,
      child: Column(children: widgets),
    );
  }
}

SimpleDialogOption createOptionItem(
    BuildContext context, String text, String value) {
  return SimpleDialogOption(
    child: Text(text),
    onPressed: () {
      Navigator.pop(context, value);
    },
  );
}

/*
void showTradingScoreRequestDialog2(BuildContext context, game.Game gameData) {
  final requestScoreMap = gameData.member.map((key, value) => MapEntry(key, 0));
  final widgets = gameData.table.playerDataMap.entries.map((e) {
    final peerId = e.key;
    final name = gameData.member[peerId];
    final socre = requestScoreMap[peerId];
    return createOptionItem(context, name, peerId);
  });

  showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: [
            createOptionItem(context, "親上がり", "leaderWin"),
            createOptionItem(context, "子上がり", "leaderLose"),
          ],
        );
      });
}
*/
