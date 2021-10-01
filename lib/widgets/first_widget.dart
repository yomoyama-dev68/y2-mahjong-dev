import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html';

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
      body: Center(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    String link = "${window.location.href}?roomId=${roomId}";
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
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
      Text("このリンクを他のプレイヤーに送ってください。"),
      ElevatedButton(
          onPressed: () {
            window.open('https://developer.mozilla.org/ja/docs/Web/API/Window/open', '');
          },
          child: Text("操作方法"))
    ]);
  }
}
