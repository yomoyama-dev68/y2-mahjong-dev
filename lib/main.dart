import 'package:flutter/material.dart';
import 'package:web_app_sample/table_widget.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  void pass(){}
  Widget _buildElevatedButton(String text, Function() func){
    return ElevatedButton(
      child: Text(text),
      style: ElevatedButton.styleFrom(
        primary: Colors.orange,
        onPrimary: Colors.white,
      ),
      onPressed: func,
    );
  }

  Widget _buildNewGamePage() {
    return Center(
        child: Column(children: [
          _buildElevatedButton("New Game", pass),
          _buildElevatedButton("Join Room", pass),
        ])
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    print(size);
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: GameTableWidget() //Image.asset("images/manzu_all/p_ms1_0.gif") // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
