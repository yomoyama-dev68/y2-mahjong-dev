import 'package:flutter/material.dart';
import '../game_controller.dart' as game;

Future<int?> showRollbackDialog(BuildContext context, game.Game gameData) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(children: _options(context, gameData));
      });
}

List<Widget> _options(BuildContext context, game.Game gameData) {
  final widgets = <Widget>[];
  final setFirstDrawable = false;
  for (int i = 0; i < gameData.tableDataLogs.length; i++) {
    final data = gameData.tableDataLogs[i];
    final updatedFor = data["updatedFor"]!;
    if (["_setupHand3", "handleDiscardTile"].contains(updatedFor)) {
      late String text;
      if (updatedFor == "_setupHand3") {
        final turnedPeerId = data["turnedPeerId"]!;
        final peerId = gameData.table.toCurrentPeerId(turnedPeerId);
        final playerName = gameData.member[peerId];
        text = "${widgets.length+1}: 配牌完了";
      } else {
        final lastDiscardedPlayerPeerID = data["lastDiscardedPlayerPeerID"]!;
        final peerId = gameData.table.toCurrentPeerId(lastDiscardedPlayerPeerID);
        final playerName = gameData.member[peerId];
        text = "${widgets.length+1}: ${playerName}の打牌";
      }
      widgets.add(
        SimpleDialogOption(
          child: Text(text),
          onPressed: () {
            Navigator.pop(context, i);
          },
        ),
      );
    }
  }
  return widgets.reversed.toList();
}

void showAcceptRollbackDialog(BuildContext context, game.Game gameData) {
  print("showAcceptRollbackDialog: ${gameData.myPeerId}");
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("巻き戻します。"),
          actions: <Widget>[
            SimpleDialogOption(
              child: Text('拒否'),
              onPressed: () {
                gameData.handleRefuseRollback();
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              child: Text('OK'),
              onPressed: () {
                gameData.handleAcceptRollback();
                Navigator.pop(context);
              },
            ),
          ],
        );
      });
}
