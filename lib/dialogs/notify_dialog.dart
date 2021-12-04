import 'package:flutter/material.dart';

void showNotifyDialog(BuildContext context, {String? title, String? message}) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title == null ? null : Text(title),
          content: message == null ? null : Text(message),
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
