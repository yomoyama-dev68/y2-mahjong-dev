import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:flutter/material.dart';
import '../game_controller.dart' as game;

class ChatWidget extends StatefulWidget {
  const ChatWidget(
      {required this.gameController, required this.streamController, Key? key})
      : super(key: key);

  final game.Game gameController;
  final StreamController<MapEntry<String, String>> streamController;

  @override
  State<ChatWidget> createState() => ChatWidgetState();
}

class ChatWidgetState extends State<ChatWidget> {
  static const nameTextStyle = TextStyle(
    color: Colors.white,
  );

  static const messageTextStyle = TextStyle(
    color: Colors.white,
  );

  late StreamSubscription subscription;
  final textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final contentKey = GlobalKey();

  game.Game g() {
    return widget.gameController;
  }

  List<MapEntry> getMessages() {
    return widget.gameController.chatMessages;
  }

  void _onChat() {
    setState(() {
      final size = contentKey.currentContext!.size!;
      scrollController.animateTo(
        size.height,
        duration: const Duration(seconds: 1),
        curve: Curves.ease,
      );
      print("_onChat:");
    });
  }

  @override
  void initState() {
    super.initState();
    subscription = widget.streamController.stream.listen((_) {
      _onChat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = getMessages();
    final myPeerId = g().myPeerId;

    final widgets = <Widget>[];
    for (final message in messages) {
      final peerId = message.key;
      var name = g().member[peerId];
      name ??= g().audienceMap[peerId];
      name ??= 'unknown';

      widgets.add(
        Align(
            alignment:
                peerId == myPeerId ? Alignment.topRight : Alignment.topLeft,
            child: buildMessageCard(name, message.value, peerId != myPeerId)),
      );
    }

    final maxHeight = window.innerHeight! * 0.6;
    final maxWidth = window.innerWidth! * 0.6;

    return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxHeight, maxHeight: maxWidth),
        child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              key: contentKey,
              mainAxisSize: MainAxisSize.min,
              children: widgets,
            )));
  }

  Widget buildMessageCard(String name, String message, bool start) {
    return Card(
        margin: start
            ? const EdgeInsets.fromLTRB(5, 5, 20, 5)
            : const EdgeInsets.fromLTRB(20, 5, 5, 5),
        elevation: 10,
        color: Colors.lightBlueAccent,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: nameTextStyle, overflow: TextOverflow.ellipsis),
              Text(
                message,
                style: messageTextStyle,
                overflow: TextOverflow.clip,
              )
            ],
          ),
        ));
  }
}
