import 'package:flutter/material.dart';
import 'game_controller.dart' as game;

void showChangeLeaderContinuousCountDialog(
    BuildContext context, game.Game gameData) {
  final content = LeaderContinuousCountWidget(
    gameData: gameData,
  );

  showDialog(
      context: context,
      builder: (BuildContext _context) {
        return AlertDialog(
          title: Text("場数を変更します。"),
          content: content,
          actions: <Widget>[
            SimpleDialogOption(
              child: Text('キャンセル'),
              onPressed: () {
                Navigator.pop(_context);
              },
            ),
            SimpleDialogOption(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(_context);
                content.state.first.doRequest();
              },
            ),
          ],
        );
      });
}

class LeaderContinuousCountWidget extends StatefulWidget {
  LeaderContinuousCountWidget({Key? key, required this.gameData})
      : super(key: key);

  final game.Game gameData;
  final state = <_LeaderContinuousCountWidgetState>[];

  @override
  _LeaderContinuousCountWidgetState createState() =>
      _LeaderContinuousCountWidgetState();
}

class _LeaderContinuousCountWidgetState
    extends State<LeaderContinuousCountWidget> {
  int count = 0;

  @override
  void initState() {
    super.initState();
    count = _g().table.leaderContinuousCount;
    widget.state.add(this);
  }

  game.Game _g() {
    return widget.gameData;
  }

  void doRequest() {
    _g().setLeaderContinuousCount(count);
  }

  void _addToCount(int value) {
    setState(() {
      count += value;
      count = count < 0 ? 0 : count;
      count = count > 8 ? 8 : count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () => _addToCount(-1),
          child: Icon(Icons.arrow_left),
        ),
        Text("${count}本場"),
        ElevatedButton(
            onPressed: () => _addToCount(1), child: Icon(Icons.arrow_right)),
      ],
    );
  }
}
