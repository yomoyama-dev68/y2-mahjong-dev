import 'package:flutter/material.dart';
import '../game_controller.dart' as game;
import '../table_controller.dart' as tbl;

Future<int?> showRollbackDialog(
    BuildContext context, game.Game gameData, Map<String, Image> imageMap) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(children: _options(context, gameData, imageMap));
      });
}

Image _getTileImage(Map<String, Image> imageMap, int tile, [direction = 0]) {
  // direction = 0: 打牌(上向, 1: 打牌(左向, 2: 打牌(下向, 3: 打牌(右向, 4: 自牌(上向,
  final info = tbl.TileInfo(tile);
  final key = "${info.type}_${info.number}_${direction}";
  final image = imageMap[key]!;
  return image;
}

Widget _buildOptionContent(
    BuildContext context,
    game.Game gameData,
    Map<String, dynamic> data,
    Map<String, Image> imageMap,
    String updatedFor) {
  if (updatedFor == "_setupHand3") {
    return Text("配牌完了");
  }

  final lastDiscardedPlayerPeerID = data["lastDiscardedPlayerPeerID"]!;
  final peerId = gameData.table.toCurrentPeerId(lastDiscardedPlayerPeerID);
  final playerName = gameData.member[peerId];
  final lastDiscardedTile = data["lastDiscardedTile"]!;
  final image = _getTileImage(imageMap, lastDiscardedTile);
  return Row(
    children: [
      SizedBox(height: 35, child: image),
      SizedBox(width: 10),
      Text("${playerName}の打牌"),
    ],
  );
}

List<Widget> _options(
    BuildContext context, game.Game gameData, Map<String, Image> imageMap) {
  final widgets = <Widget>[];
  for (int i = 0; i < gameData.tableDataLogs.length; i++) {
    final data = gameData.tableDataLogs[i];
    final updatedFor = data["updatedFor"]!;
    if (["_setupHand3", "handleDiscardTile"].contains(updatedFor)) {
      late String text;
      widgets.add(
        SimpleDialogOption(
          child: _buildOptionContent(
            context,
            gameData,
            data,
            imageMap,
            updatedFor,
          ),
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
