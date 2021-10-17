import 'package:flutter/material.dart';
import 'package:y2_mahjong/widgets/chat_widget.dart';
import 'dart:async';
import '../game_controller.dart' as game;

class ChatDialog {
  static final globalKey = GlobalKey();

  static bool isOpening() {
    return globalKey.currentContext != null;
  }

  static void showChatDialog(BuildContext context, game.Game gameController,
      StreamController<MapEntry<String, String>> streamController) {
    final textController = TextEditingController();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            key: globalKey,
            title: const Text('チャット'),
            content: ChatWidget(
              gameController: gameController,
              streamController: streamController,
            ),
            actions: [
              TextField(
                maxLines: null,
                controller: textController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                autofocus: false,
                keyboardType: TextInputType.text,
              ),
              TextButton(
                  onPressed: () {
                    gameController.sendChatMessage(textController.text);
                    textController.text = "";
                  },
                  child: const Text('送信')),
            ],
          );
        });
  }
}
