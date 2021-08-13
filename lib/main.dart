import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:web_app_sample/top_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
    print(
        "generateRoute: name=${settings.name}, arguments=${settings.arguments}");

    final paths = settings.name!.split('?');
    final path = paths[0];
    final queryParameters = Uri.splitQueryString(paths[1]);

    final String roomId = queryParameters["roomId"] ?? const Uuid().v4();

    switch (path) {
      case '/':
        return MaterialPageRoute(
            builder: (_) => TopWidget(roomId: roomId));
    }

    return null;
  }
}
