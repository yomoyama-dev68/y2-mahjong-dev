import 'dart:math';

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
      onGenerateRoute: _generateRoute,
      initialRoute: '/',
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

  static String? _getRoomId(String? url) {
    if (url == null) return null;

    final paths = url.split('?');
    if (paths.length < 2) {
      return null;
    }
    return Uri.splitQueryString(paths.last)["roomId"];
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    print("generateRoute: name=${settings.name}, "
        "arguments=${settings.arguments}, "
        "${window.location.href}");

    String? roomId = _getRoomId(settings.name);
    if (roomId != null) {
      return MaterialPageRoute(builder: (_) => TopWidget(roomId: roomId));
    }
    return MaterialPageRoute(
        builder: (_) => FirstWidget(roomId: _generateRoomId()));
  }

  static _generateRoomId() {
    final p0 = randomString(3);
    final p1 = randomString(4);
    final p2 = randomString(3);
    return "${p0}-${p1}-${p2}";
  }

  static String randomString(int length) {
    const _randomChars = "abcdefghijklmnopqrstuvwxyz0123456789";
    const _charsLength = _randomChars.length;
    final rand = Random();
    final codeUnits = List.generate(
      length,
      (index) {
        final n = rand.nextInt(_charsLength);
        return _randomChars.codeUnitAt(n);
      },
    );
    return String.fromCharCodes(codeUnits);
  }
}
