import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:web_app_sample/widgets/first_widget.dart';
import 'package:web_app_sample/widgets/top_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dart:html';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const locale = Locale("ja", "JP");
    return MaterialApp(
      title: 'Flutter Demo',
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        locale,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: "Noto Sans JP",
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    print("${window.location.href}");
    final paths = window.location.href.split('?');
    if (paths.length <= 1) {
      return FirstWidget(roomId: const Uuid().v4());
    }
    final queryParameters = Uri.splitQueryString(paths[1]);
    print("queryParameters: ${queryParameters}");
    final String? roomId = queryParameters["roomId"];
    print("roomId: ${roomId}");
    if (roomId == null) {
      return FirstWidget(roomId: const Uuid().v4());
    } else {
      return TopWidget(roomId: roomId);
    }
  }
}