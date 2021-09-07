import 'package:flutter/material.dart';
import '../game_controller.dart' as game;

void showRequestNextHandDialog(BuildContext context, game.Game gameData) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('次の局を始めますか？'),
          actions: <Widget>[
            SimpleDialogOption(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              child: Text('連荘'),
              onPressed: () {
                Navigator.pop(context);
                gameData.requestNextHand("continueLeader");
              },
            ),
            SimpleDialogOption(
              child: Text('親流れ'),
              onPressed: () {
                Navigator.pop(context);
                gameData.requestNextHand("nextLeader");
              },
            ),
            _buildPopupMenu(context, gameData),
          ],
        );
      });
}

PopupMenuButton _buildPopupMenu(BuildContext context, game.Game gameData) {
  void _onSelectedPopupMenu(String menu) {
    if (menu == "previousLeader") {
      Navigator.pop(context);
      gameData.requestNextHand("previousLeader");
    }
  }

  return PopupMenuButton<String>(
    onSelected: _onSelectedPopupMenu,
    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: "previousLeader",
        child: Text('一局戻す。'),
      ),
    ],
  );
}

final _acceptNextHandDialogContext = <BuildContext>[];

void showAcceptNextHandDialog(
    BuildContext context, game.Game gameData, String text) {
  print("showAcceptNextHandDialog: ${gameData.myPeerId}");
  showDialog(
      context: context,
      builder: (BuildContext context) {
        _acceptNextHandDialogContext.add(context);
        return AlertDialog(
          title: Text(text),
          actions: <Widget>[
            SimpleDialogOption(
              child: Text('拒否'),
              onPressed: () {
                Navigator.pop(context);
                gameData.refuseNextHand();
              },
            ),
            SimpleDialogOption(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                gameData.acceptNextHand();
              },
            ),
          ],
        );
      });
}

void showAcceptDrawGameDialog(BuildContext context, game.Game gameData) {
  print("showAcceptNextHandDialog: ${gameData.myPeerId}");
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("流局します。"),
          actions: <Widget>[
            SimpleDialogOption(
              child: Text('拒否'),
              onPressed: () {
                Navigator.pop(context);
                gameData.refuseDrawGame();
              },
            ),
            SimpleDialogOption(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                gameData.acceptDrawGame();
              },
            ),
          ],
        );
      });
}

void showAcceptGameResetDialog(BuildContext context, game.Game gameData) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("ゲームを最初から始めます。"),
          actions: <Widget>[
            SimpleDialogOption(
              child: Text('拒否'),
              onPressed: () {
                Navigator.pop(context);
                gameData.refuseGameReset();
              },
            ),
            SimpleDialogOption(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                gameData.acceptGameReset();
              },
            ),
          ],
        );
      });
}
