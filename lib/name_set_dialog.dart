import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NameSetDialog extends StatefulWidget {
  const NameSetDialog({Key? key, required this.name}) : super(key: key);

  final String name;

  static Future<String?> show(BuildContext context, String currentName) {
    final dialog = NameSetDialog(name: currentName);
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return dialog;
      },
    );
  }

  @override
  State createState() => NameSetDialogState();
}

class NameSetDialogState extends State<NameSetDialog> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = [
      ElevatedButton(
        child: const Text("OK"),
        onPressed: () {
          Navigator.pop<String>(context, _textController.text);
        },
      ),
    ];

    return AlertDialog(
      title: const Text("プレイヤー名を入力してください"),
      content: TextField(
        controller: _textController,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        autofocus: true,
        keyboardType: TextInputType.text,
      ),
      actions: actions,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
