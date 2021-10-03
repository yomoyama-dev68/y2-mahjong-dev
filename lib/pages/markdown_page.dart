import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';


class MarkDownPage extends StatelessWidget {
  const MarkDownPage({Key? key, required this.markdownText}) : super(key: key);

  final String markdownText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Markdown(data: markdownText),
    );
  }
}