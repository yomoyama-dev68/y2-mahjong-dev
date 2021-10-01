import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html';

import 'package:web_app_sample/widgets/top_icon.dart';

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
      const SizedBox(height: 20,),
      Row(mainAxisSize: MainAxisSize.min, children: [
        FloatingActionButton(
            onPressed: () {
              _showLinkDialog(context, link);
            },
            child: const Text("開始")
        ),
        const SizedBox(width: 20,),
        FloatingActionButton(
            onPressed: () {
              window.open(
                  'https://developer.mozilla.org/ja/docs/Web/API/Window/open',
                  '');
            },
            child: const Text("遊び方")
        )
      ]),
    ]);
  }

  void _showLinkDialog(BuildContext context, String link) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("このリンクを他のプレイヤーに送ってください。"),
            content: Row(mainAxisSize: MainAxisSize.min, children: [
              SelectableText.rich(TextSpan(
                children: <TextSpan>[
                  TextSpan(text: link, style: linkStyle),
                ],
              )),
              IconButton(
                icon: const Icon(Icons.content_copy),
                tooltip: 'copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                },
              ),
            ]),
            actions: <Widget>[
              SimpleDialogOption(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }
}
