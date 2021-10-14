import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NameSetResult {
  NameSetResult(this.name, this.asPlayer, this.isClosed);

  final String name;
  final bool asPlayer;
  final bool isClosed;
}

class NameSetDialog extends StatefulWidget {
  static final globalKey = GlobalKey();

  const NameSetDialog({Key? key, required this.asAudience}) : super(key: key);

  final bool? asAudience;

  static Future<NameSetResult?> show(BuildContext context, {bool? asAudience}) {
    final dialog = NameSetDialog(asAudience: asAudience);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return dialog;
      },
    );
  }

  static void close() {
    if (globalKey.currentContext != null) {
      Navigator.pop<NameSetResult>(
          globalKey.currentContext!, NameSetResult("", false, true));
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
        child: const Text("観戦者として参加"),
        onPressed: () {
          Navigator.pop<NameSetResult>(
              context, NameSetResult(_textController.text, false, false));
        },
      ),
    ];

    if (widget.asAudience != true) {
      actions.add(ElevatedButton(
        child: const Text("プレイヤーとして参加"),
        onPressed: () {
          Navigator.pop<NameSetResult>(
              context, NameSetResult(_textController.text, true, false));
        },
      ));
    }

    return AlertDialog(
      key: NameSetDialog.globalKey,
      title: const Text("名前を入力してください"),
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
    widgets.add(SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context, "asAudience");
      },
      child: Text("観戦者"),
    ));

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
