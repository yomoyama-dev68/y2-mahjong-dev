import 'package:flutter/material.dart';
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
                content.doRequest();
                Navigator.pop(context);
              },
            ),
          ],
        );
      });
}

class TradingScoreRequestWidget extends StatelessWidget {
  TradingScoreRequestWidget({Key? key, required this.gameData})
      : super(key: key);

  final game.Game gameData;
  final textControllerMap = <String, TextEditingController>{};

  void doRequest() {
    final request = textControllerMap
        .map((key, value) => MapEntry(key, int.tryParse(value.text) ?? 0));
    request.removeWhere((key, value) => value == 0);
    gameData.requestScore(request);
  }

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    for (final e in gameData.member.entries) {
      final textController = TextEditingController();
      if (gameData.myPeerId == e.key) continue;
      textControllerMap[e.key] = textController;
      widgets.add(TextField(
        controller: textController,
        decoration: InputDecoration(
            labelText: "${e.value}へ", border: OutlineInputBorder()),
        autofocus: true,
        keyboardType: TextInputType.number,
      ));
      widgets.add(const SizedBox(
        height: 10,
      ));
    }

    return SingleChildScrollView(
      child: Column(children: widgets),
    );
  }
}
