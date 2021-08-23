import 'package:flutter/material.dart';

class PlayerStateTile extends StatelessWidget {
  PlayerStateTile(this.wind, this.name, this.score, this.riichi); // コンストラクタで引数を受け取る

  static const windTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
  );
  static const contentTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
  );

  final String wind;
  final String name;
  final int score;
  final bool riichi;

  int _score() {
    if (riichi) return score - 1000;
    return  score;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
        opacity: 0.6,
        child: Container(
            decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(5))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                    child: Text(
                      wind,
                      style: windTextStyle,
                    )),
                Padding(
                    padding: EdgeInsets.all(5),
                    child: SizedBox(
                        width: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: contentTextStyle,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              '${_score()}',
                              style: contentTextStyle,
                              textAlign: TextAlign.right,
                            )
                          ],
                        )))
              ],
            )));
  }
}
