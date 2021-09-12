import 'package:flutter/material.dart';
import '../game_controller.dart' as game;

class QuickScoreSelectorDialog {
  static Future<String?> show(BuildContext context, game.Game g) async {
    final winner = await selectWinner(context);
    final ronOrTsumo = await selectRonOrTsumo(context);
    final level = await selectLevel(context);
    if (["1", "2", "3", "4", ].contains(level)) {
      final subLevel = await selectSubLevel(context);
    }
  }

  static SimpleDialogOption createOptionItem(
      BuildContext context, String text, String value) {
    return SimpleDialogOption(
      child: Text(text),
      onPressed: () {
        Navigator.pop(context, value);
      },
    );
  }

  static Future<String?> selectWinner(BuildContext context) {
    return showDialog(
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

  static Future<String?> selectRonOrTsumo(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(children: [
            createOptionItem(context, "ロン上がり", "ron"),
            createOptionItem(context, "ツモ上がり", "tsumo"),
          ]);
        });
  }

  static Future<String?> selectLevel(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              createOptionItem(context, "1翻", "1"),
              createOptionItem(context, "2翻", "2"),
              createOptionItem(context, "3翻", "3"),
              createOptionItem(context, "4翻", "4"),
              createOptionItem(context, "5翻", "5"),
              createOptionItem(context, "6~7翻", "6-7"),
              createOptionItem(context, "8~10翻", "8-10"),
              createOptionItem(context, "11~12翻", "11-12"),
              createOptionItem(context, "13翻", "13"),
              createOptionItem(context, "役満", "yakuman"),
            ],
          );
        });
  }

  static Future<String?> selectSubLevel(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            children: [
              createOptionItem(context, "20符", "20"),
              createOptionItem(context, "30符", "30"),
              createOptionItem(context, "40符", "40"),
              createOptionItem(context, "50符", "50"),
              createOptionItem(context, "60符", "60"),
              createOptionItem(context, "70符", "70"),
            ],
          );
        });
  }

}
