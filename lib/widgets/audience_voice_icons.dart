import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:y2_mahjong/widgets/voiced_icon.dart';
import '../game_controller.dart' as game;

class AudienceVoiceIcons extends StatefulWidget {
  const AudienceVoiceIcons(
      {required this.gameController, required this.streamController, Key? key})
      : super(key: key);

  final game.Game gameController;
  final StreamController<String> streamController;

  @override
  State<AudienceVoiceIcons> createState() => AudienceVoiceIconsState();
}

class AudienceVoiceIconsState extends State<AudienceVoiceIcons> {
  final globalKeyMap = <String, GlobalKey>{};
  final sizeMap = <String, Size>{};
  final vociedList = [];
  late StreamSubscription subscription;
  var width = 5.0;
  var height = 5.0;

  static const contentTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
  );

  game.Game g() {
    return widget.gameController;
  }

  void _onVoiced(String peerId) {
    setState(() {
      vociedList.remove(peerId);
      vociedList.add(peerId);
      print("onVoiced: vociedList: ${vociedList}");
    });
  }

  @override
  void initState() {
    super.initState();
    vociedList.addAll(g().audienceMap.keys);
    subscription = widget.streamController.stream.listen((voicedPeerId) {
      _onVoiced(voicedPeerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((cb) {
      final oldWidth = width;
      final oldHeight = height;

      width = 5.0;
      print(
          "AudienceVoiceIconsState: addPostFrameCallback: globalKeyMap.keys: ${globalKeyMap.keys.toList()}");
      for (final e in globalKeyMap.entries) {
        RenderBox? box =
            e.value.currentContext!.findRenderObject() as RenderBox?;
        print("${e.key}: box: ${box}");

        if (box != null) {
          sizeMap[e.key] = Size.copy(box.size);
          print("${e.key}: box: ${box.size}");

          width += box.size.width + 5.0;
          height = box.size.height > height ? box.size.height : height;
        }
      }

      if (oldWidth != width || oldHeight != height) {
        setState(() {});
      }
    });

    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(children: buildNameTiles()),
        ));
  }

  List<Widget> buildNameTiles() {
    print("buildNameTiles: globalKeyMap.keys: ${globalKeyMap.keys.toList()}");

    final widgets = <Widget>[];
    var leftOffset = 5.0;
    for (final peerId in vociedList.reversed) {
      final name = g().audienceMap[peerId];
      if (name == null) {
        continue;
      }
      var size = sizeMap[peerId];
      if (size == null) {
        size = const Size(0, 0);
        sizeMap[peerId] = size;
      }

      var key = globalKeyMap[peerId];
      if (key == null) {
        key = GlobalKey();
        globalKeyMap[peerId] = key;
      }

      widgets.add(AnimatedPositioned(
        key: key,
        left: leftOffset,
        duration: const Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
        child: buildNameTile(peerId),
      ));
      leftOffset += 5.0 + size.width;
    }

    return widgets;
  }

  Widget buildNameTile(String peerId) {
    final name = g().audienceMap[peerId]!;
    final enabledAudio = g().membersAudioState[peerId] ?? false;
    return Container(
        decoration: const BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.all(Radius.circular(5))),
        child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoicedIcon(
              peerId: peerId,
              streamController: widget.streamController,
              micOff: !enabledAudio,
              color: Colors.white,
            ),
            const SizedBox(
              width: 5,
            ),
            Text(
              name,
              style: contentTextStyle,
            )
          ],
        )));
  }
}

class AudienceVoiceIconsTest extends StatefulWidget {
  const AudienceVoiceIconsTest({Key? key}) : super(key: key);

  @override
  State<AudienceVoiceIconsTest> createState() => AudienceVoiceIconsTestState();
}

class AudienceVoiceIconsTestState extends State<AudienceVoiceIconsTest> {
  final globalKeyMap = <String, GlobalKey>{};
  final sizeMap = <String, Size>{};
  final members = {"a": "AAA", "b": "B", "c": "CCCCCC"};
  final vociedList = [];

  void onVoiced(String peerId) {
    setState(() {
      vociedList.remove(peerId);
      vociedList.add(peerId);
      print("onVoiced: vociedList: ${vociedList}");
    });
  }

  @override
  void initState() {
    super.initState();
    vociedList.addAll(members.keys);
    Timer.periodic(
      const Duration(seconds: 3),
      _onTimer,
    );
  }

  void _onTimer(Timer timer) {
    int num = Random().nextInt(vociedList.length);
    onVoiced(vociedList[num]);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((cb) {
      print(
          "addPostFrameCallback: globalKeyMap.keys: ${globalKeyMap.keys.toList()}");
      for (final e in globalKeyMap.entries) {
        RenderBox? box =
            e.value.currentContext!.findRenderObject() as RenderBox?;
        print("${e.key}: box: ${box}");

        if (box != null) {
          sizeMap[e.key] = Size.copy(box.size);
          print("${e.key}: box: ${box.size}");
        }
      }
    });

    return SizedBox(
      width: 500,
      height: 100,
      child: Stack(
        children: buildNameTiles(),
      ),
    );
  }

  List<Widget> buildNameTiles() {
    print("buildNameTiles: globalKeyMap.keys: ${globalKeyMap.keys.toList()}");

    final widgets = <Widget>[];
    var leftOffset = 5.0;
    for (final peerId in vociedList.reversed) {
      final name = members[peerId];
      if (name == null) {
        continue;
      }
      var size = sizeMap[peerId];
      if (size == null) {
        size = Size(0, 0);
        sizeMap[peerId] = size;
      }

      var key = globalKeyMap[peerId];
      if (key == null) {
        key = GlobalKey();
        globalKeyMap[peerId] = key;
      }

      widgets.add(AnimatedPositioned(
        key: key,
        left: leftOffset,
        duration: const Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
        child: Container(
          color: Colors.blue,
          child: Center(child: Text(name)),
        ),
      ));
      leftOffset += 5.0 + size.width;
    }

    return widgets;
  }
}
