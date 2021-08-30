import 'package:flutter/material.dart';
import 'table_controller.dart' as tbl;

class StageInfoWidget extends StatelessWidget {
  const StageInfoWidget({Key? key, required this.table, required this.imageMap})
      : super(key: key);

  static const windTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 30,
    fontFamily: 'Hkkaikk',
  );
  static const remainTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
  );
  static const contentTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
  );

  final tbl.Table table;
  final Map<String, Image> imageMap;

  @override
  Widget build(BuildContext context) {
    final stages = [
      "東",
      "南",
      "西",
      "北",
    ];
    final hands = [
      "一局",
      "二局",
      "三局",
      "四局",
    ];

    final stage = stages[table.leaderChangeCount ~/ 4];
    final handNum = hands[table.leaderChangeCount % 4];
    final remainTiles = table.wallTiles.length;
    final leaderContinuousCount = table.leaderContinuousCount;
    var riichiCount = table.remainRiichiBarCounts;
    //　リーチ棒の精算
    for (final data in table.playerDataMap.values) {
      if (data.riichiTile.isNotEmpty) riichiCount += 1;
    }

    return Opacity(
        opacity: 0.6,
        child: SizedBox(
            width: 150,
            child: Container(
                decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                padding: const EdgeInsets.all(5),
                child: Column(children: [
                  Text("${stage}${handNum}", style: windTextStyle),
                  const SizedBox(
                    height: 5,
                  ),
                  Center(
                      child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "残 ${remainTiles}",
                        style: remainTextStyle,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          imageMap["bar_leader_continuous_count_mini"]!,
                          Text("×${leaderContinuousCount}",
                              style: contentTextStyle),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          imageMap["bar_riichi_mini"]!,
                          Text(
                            "x${riichiCount}",
                            style: contentTextStyle,
                          )
                        ]),
                      ])
                    ],
                  ))
                ]))));
  }
}
