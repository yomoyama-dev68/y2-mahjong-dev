import 'package:flutter/material.dart';
import '../game_controller.dart' as game;

void showGetRiichiBarScoreDialogAll(BuildContext context, game.Game gameData) {
  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext _context) {
        return AlertDialog(
          title: Text("点棒を回収します。"),
          actions: <Widget>[
            SimpleDialogOption(
              child: Text('OK'),
              onPressed: () {
                Navigator.pop(_context);
                gameData.handleGetRiichiBarScoreAll();
              },
            ),
          ],
        );
      });
}

class GetRiichiBarScoreWidget extends StatefulWidget {
  GetRiichiBarScoreWidget({Key? key, required this.gameData})
      : super(key: key);

  final game.Game gameData;
  final state = <_GetRiichiBarScoreWidgetState>[];

  @override
  _GetRiichiBarScoreWidgetState createState() =>
      _GetRiichiBarScoreWidgetState();
}

class _GetRiichiBarScoreWidgetState
    extends State<GetRiichiBarScoreWidget> {
  late int count;

  @override
  void initState() {
    super.initState();
    count = _g().table.remainRiichiBarCounts;
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
      final limit = _g().table.remainRiichiBarCounts;
      count += value;
      count = count < 0 ? 0 : count;
      count = count > limit ? limit : count;
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
        Text("${count}本"),
        ElevatedButton(
            onPressed: () => _addToCount(1), child: Icon(Icons.arrow_right)),
      ],
    );
  }
}
