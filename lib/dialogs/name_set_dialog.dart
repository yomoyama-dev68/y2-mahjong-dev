import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NameSetDialog extends StatefulWidget {
  static final globalKey = GlobalKey();

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

  static void close() {
    if (globalKey.currentContext != null) {
      Navigator.pop<String>(globalKey.currentContext!, "close");
    }
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
      key: NameSetDialog.globalKey,
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

class RejoinNameSelectDialog {
  static Future<String?> show(
      BuildContext context, List<String> lostPlayerNames) {
    final widgets = <Widget>[];
    for (final name in lostPlayerNames) {
      widgets.add(SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, name);
        },
        child: Text(name),
      ));
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final dialog = SimpleDialog(
          title: const Text('どのプレイヤーだったか選んでください。'),
          children: widgets,
        );
        return dialog;
      },
    );
  }
}
