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
    print("${window.location.href}");
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
      onGenerateRoute: RouteGenerator.generateRoute,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TopWidget(roomId: const Uuid().v4()),
    );
  }
}

class RouteGenerator {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    print("generateRoute: name=${settings.name}, "
        "arguments=${settings.arguments}, "
        "${window.location.href}");

    final paths = settings.name!.split('?');
    final path = paths[0];
    final queryParameters = Uri.splitQueryString(paths[1]);

    final String? roomId = queryParameters["roomId"];
    switch (path) {
      case '/':
        if (roomId == null) {
          return MaterialPageRoute(
              builder: (_) => FirstWidget(roomId: const Uuid().v4()));
        } else {
          return MaterialPageRoute(builder: (_) => TopWidget(roomId: roomId));
        }
    }
    return null;
  }
}
