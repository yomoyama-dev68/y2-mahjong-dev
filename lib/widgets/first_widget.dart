import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html';

import 'package:y2_mahjong/widgets/top_icon.dart';

class FirstWidget extends StatelessWidget {
  const FirstWidget({Key? key, required this.roomId}) : super(key: key);

  final String roomId;
  static const baseStyle = TextStyle(
    fontSize: 20,
  );
  static const linkStyle = TextStyle(color: Colors.indigo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    String link = "${window.location.href}?roomId=${roomId}";

    return Column(mainAxisSize: MainAxisSize.min, children: [
      const TopIcon(),
      const SizedBox(
        height: 20,
      ),
      Row(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton(
            onPressed: () {
              _showLinkDialog(context, link);
            },
            child: const Text("開始")),
        const SizedBox(
          width: 20,
        ),
        FloatingActionButton(
            onPressed: () {
              window.open(
                  'https://developer.mozilla.org/ja/docs/Web/API/Window/open',
                  '');
            },
            child: const Text("遊び方"))
      ]),
    ]);
  }

  void _showLinkDialog(BuildContext context, String link) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("このリンクを他のプレイヤーに送ってください。"),
            content: FittedBox(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
              SelectableText(
                link,
                style: linkStyle,
              ),
              IconButton(
                icon: const Icon(Icons.content_copy),
                tooltip: 'copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                },
              ),
            ])),
            actions: <Widget>[
              SimpleDialogOption(
                child: const Text('送った。'),
                onPressed: () {
                  _showOpenLinkDialog(context, link);
                },
              ),
            ],
          );
        });
  }

  void _showOpenLinkDialog(BuildContext context, String link) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("ゲームルームに移動します。"),
            actions: <Widget>[
              SimpleDialogOption(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              SimpleDialogOption(
                child: const Text('OK'),
                onPressed: () {
                  window.open(link, '');
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }
}
