import 'package:flutter/material.dart';
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
    return SelectableText.rich(
      TextSpan(
        style: baseStyle,
        children: <TextSpan>[
          TextSpan(text: link, style: linkStyle),
          const TextSpan(text: '\nこのリンクを他のプレイヤーに送ってください。'),
        ],
      ),
    );
  }
}
