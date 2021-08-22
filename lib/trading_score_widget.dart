import 'package:flutter/material.dart';
import 'game_controller.dart' as game;

class TradingScoreAcceptWidget extends StatelessWidget {
  const TradingScoreAcceptWidget(
      {Key? key, required this.gameData, required this.requestingScoreFrom})
      : super(key: key);

  final game.Game gameData;
  final Map<String, int> requestingScoreFrom;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[
      const Text("点棒支払を受け入れますか？"),
      const SizedBox(
        height: 10,
      )
    ];

    final textControllerMap = <String, TextEditingController>{};

    for (final e in gameData.member.entries) {
      if (gameData.myPeerId == e.key) continue;
      if (!requestingScoreFrom.containsKey(e.key)) continue;
      final score = requestingScoreFrom[e.key].toString();
      final textController = TextEditingController();
      textControllerMap[e.key] = textController;
      textController.text = score;
      widgets.add(TextField(
        controller: textController,
        readOnly: true,
        decoration: InputDecoration(
            labelText: "${e.value}から", border: const OutlineInputBorder()),
      ));
      widgets.add(const SizedBox(
        height: 10,
      ));
    }

    widgets.add(Row(children: [
      const Spacer(),
      ElevatedButton(
        child: const Text("No"),
        onPressed: () {
          gameData.refuseRequestedScore();
        },
      ),
      const SizedBox(
        width: 5,
      ),
      ElevatedButton(
        child: const Text("OK"),
        onPressed: () {
          gameData.acceptRequestedScore();
        },
      )
    ]));
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5))),
      padding: const EdgeInsets.all(5),
      child: Column(children: widgets),
    );
  }
}

class TradingScoreRequestWidget extends StatelessWidget {
  const TradingScoreRequestWidget({Key? key, required this.gameData})
      : super(key: key);

  final game.Game gameData;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[
      const Text("点棒支払"),
      const SizedBox(
        height: 10,
      )
    ];

    final textControllerMap = <String, TextEditingController>{};

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

    widgets.add(Row(children: [
      Spacer(),
      ElevatedButton(
        child: const Text("Cancel"),
        onPressed: () {
          gameData.cancelTradingScore();
        },
      ),
      const SizedBox(
        width: 5,
      ),
      ElevatedButton(
        child: const Text("OK"),
        onPressed: () {
          final request = textControllerMap.map(
              (key, value) => MapEntry(key, int.tryParse(value.text) ?? 0));
          request.removeWhere((key, value) => value == 0);
          gameData.requestScore(request);
        },
      )
    ]));
    return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5))),
      padding: const EdgeInsets.all(5),
      child: Column(children: widgets),
    );
  }
}
