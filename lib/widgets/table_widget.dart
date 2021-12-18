import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:y2_mahjong/dialogs/chat_dialog.dart';
import 'package:y2_mahjong/dialogs/get_riichi_bar_score_dialog.dart';
import 'package:y2_mahjong/dialogs/notify_dialog.dart';
import 'package:y2_mahjong/dialogs/rollback_dialog.dart';
import 'package:y2_mahjong/widgets/player_state_tile.dart';
import 'package:y2_mahjong/resources/sound_loader.dart';
import 'package:y2_mahjong/widgets/stage_info_widget.dart';
import 'package:y2_mahjong/resources/image_loader.dart';
import 'package:y2_mahjong/dialogs/trading_score_dialog.dart';
import 'package:y2_mahjong/widgets/top_icon.dart';
import 'package:y2_mahjong/widgets/voiced_icon.dart';
import 'dart:ui' as ui;
import '../table_controller.dart';
import 'actions_bar_widget.dart';
import 'audience_voice_icons.dart';
import 'called_tiles_widget.dart';
import '../commad_handler.dart';
import '../game_controller.dart' as game;
import '../dialogs/name_set_dialog.dart';
import '../dialogs/next_hand_dialog.dart';
import '../table_controller.dart' as tbl;
import 'discard_tile_animation.dart';
import 'tiles_painter.dart';
import 'table_ribbon_widget.dart';
import 'mywall_widget.dart';
import 'dart:math';
import 'dart:html';

const baseTableSize = 700;
const tappableTileScale = 0.8;

class GameTableWidget extends StatefulWidget {
  const GameTableWidget({Key? key, required this.roomId, this.playerName})
      : super(key: key);

  final String roomId;
  final String? playerName;

  @override
  _GameTableWidgetState createState() => _GameTableWidgetState();
}

class _GameTableWidgetState extends State<GameTableWidget> {
  final Map<String, ui.Image> _uiImageMap = {};
  final Map<String, Image> _imageMap = {};
  late game.Game _game;
  bool showStageAndPlayerInfo = true;
  final _streamController = StreamController<String>.broadcast();
  final _chatStreamController =
      StreamController<MapEntry<String, String>>.broadcast();
  bool _needToStartDiscardTimeAnimation = false;
  Timer? _notifyMyTurnTimer;

  @override
  void initState() {
    print("_GameTableWidgetState:initState");
    super.initState();
    loadImages(tappableTileScale)
        .then((value) => onTileImageLoaded(value.uiImageMap, value.imageMap));
    _game = game.Game(
        roomId: widget.roomId,
        onChangeGameState: onChangeGameState,
        onChangeMember: onChangeMember,
        onChangeGameTableState: onChangeGameTableState,
        onChangeGameTableData: onChangeGameTableData,
        onRequestScore: onRequestScore,
        onEventGameTable: onEventGameTable,
        onReceiveCommandResult: onReceiveCommandResult,
        onSetupLocalAudio: onSetupLocalAudio,
        onVoiced: onVoiced,
        onReceivedChatMessage: onReceivedChatMessage,
        onError: onSkyWayError);

    /*
    Timer.periodic(
      const Duration(seconds: 3),
      (Timer timer) {
        if (_game.audienceMap.length > 0) {
          int num = Random().nextInt(_game.audienceMap.length);
          onVoiced(_game.audienceMap.keys.toList()[num]);
        }
      },
    );
     */
  }

  void onSetupLocalAudio(bool enabled, String message) {
    if (!enabled) {
      showNotifyDialog(context, message: "マイクを発見できませんでした。(${message})");
    }
  }

  void onChangeGameState(game.GameState oldState, game.GameState newState) {
    print("onChangeGameState: ${_game.myPeerId}: $oldState, $newState");
    if (oldState == game.GameState.onJoiningRoom &&
        newState == game.GameState.onSettingMyName) {
      if (_game.member.length < 4) {
        _setMyName();
      } else {
        _setMyName(asAudience: true);
      }
    }
    if (_game.isAudience) {
      if (newState == game.GameState.onGame) {
        _game.setAudienceAs(_game.member.keys.first);
      }
    } else {
      if (newState == game.GameState.onNeedRejoin) {
        _rejoin();
      }
    }

    setState(() {});
  }

  void onChangeMember(List<String> oldMember, List<String> newMember) {
    setState(() {});
  }

  void onChangeGameTableState(String oldState, String newState) {
    print("onChangeGameTableState: ${_game.myPeerId}: $oldState, $newState");
    if (_game.isAudience) {
      return;
    }
    if (newState == tbl.TableState.waitingNextHandForNextLeader) {
      showAcceptNextHandDialog(context, _game, "親を流して次の局を始めます。");
    }
    if (newState == tbl.TableState.waitingNextHandForContinueLeader) {
      showAcceptNextHandDialog(context, _game, "連荘で次の局を始めます。");
    }
    if (newState == tbl.TableState.waitingNextHandForPreviousLeader) {
      showAcceptNextHandDialog(context, _game, "一局戻します。");
    }
    if (newState == tbl.TableState.waitingDrawGame) {
      showAcceptDrawGameDialog(context, _game);
    }
    if (newState == tbl.TableState.waitingGameReset) {
      showAcceptGameResetDialog(context, _game);
    }
    if (newState == tbl.TableState.waitingRollbackFromDrawable ||
        newState == tbl.TableState.waitingRollbackFromProcessingFinishHand) {
      showAcceptRollbackDialog(context, _game);
    }
    if (newState == tbl.TableState.called) {
      if (_game.table.turnedPeerId != _game.myPeerId) {
        final callerName = _game.member[_game.table.turnedPeerId]!;
        Fluttertoast.showToast(
            msg: "${callerName}が鳴こうとしています。",
            webPosition: "center",
            timeInSecForIosWeb: 2);
      }
    }

    if (newState == tbl.TableState.processingFinishHand) {
      if (_game.table.lastWinner == _game.myPeerId && _game.existRiichiBar()) {
        showGetRiichiBarScoreDialogAll(context, _game);
      }
      if (_game.table.lastWinner != _game.myPeerId) {
        final winnerName = _game.member[_game.table.lastWinner];
        if (winnerName != null) {
          showNotifyDialog(context, message: "${winnerName}さんがアガリました。");
        }
      }
    }
  }

  void onChangeGameTableData(String updatedFor) {
    print("onChangeGameTableData");
    if (!game.soundOnlyOwner || _game.isOwner()) {
      final soundMap = <String, Function>{
        "_setupHand2": Sounds.drawTile,
        "_setupHand3": Sounds.sortTiles,
        "handleDrawTile": Sounds.drawTile,
        "handleDiscardTile": Sounds.discardTile,
        "handlePongOrChow": Sounds.sortTiles,
        "handleOpenKan": Sounds.sortTiles,
        "handleCloseKan": Sounds.sortTiles,
        "handleLateKan": Sounds.sortTiles,
        "handleOpenTiles": Sounds.openMyWall,
        "handleWin": Sounds.call,
        "handleRequestNextHand": Sounds.call,
        "handleCall": Sounds.call,
        "handleCancelCall": Sounds.call,
        "handleRequestDrawGame": Sounds.call,
      };
      soundMap[updatedFor]?.call();
    }
    if (updatedFor == "handleDiscardTile") {
      _needToStartDiscardTimeAnimation = true;
    }
    setState(() {});
  }

  void onRequestScore(String requester, int score) {
    showTradingScoreAcceptDialog(context, _game, requester, score);
  }

  void onEventGameTable(String event) {
    if (event == "onMyTurned") {
      Timer(const Duration(seconds: 5), () {
        if (_game.isMyTurn() && _game.table.state == TableState.drawable) {
          showNotifyDialog(context, message: "あなたの番です。");
        }
      });
    }
    setState(() {});
  }

  void onReceiveCommandResult(CommandResult result) {
    setState(() {});
  }

  void onVoiced(String peerId) {
    _streamController.sink.add(peerId);
  }

  void onReceivedChatMessage(String peerId, String message) {
    _chatStreamController.sink.add(MapEntry(peerId, message));
    if (!ChatDialog.isOpening()) {
      var name = _game.member[peerId];
      name ??= _game.audienceMap[peerId];
      name ??= 'unknown';
      Fluttertoast.showToast(
          msg: "${name}\n${message}",
          webPosition: "center",
          timeInSecForIosWeb: 5);
    }
  }

  Future<void> _setMyName({bool? asAudience}) async {
    if (widget.playerName != null) {
      _game.setMyName(widget.playerName!);
      return;
    }
    while (true) {
      final result = await NameSetDialog.show(context, asAudience: asAudience);
      print("NameSetDialog: ${result}");
      if (result == null) {
        return;
      }
      if (result.isClosed) {
        return;
      }
      if (result.name.isEmpty) {
        continue;
      }
      if (result.asPlayer) {
        _game.setMyName(result.name);
        return;
      } else {
        _game.joinAsAudience(result.name);
        return;
      }
    }
  }

  Future<void> _rejoin() async {
    NameSetDialog.close();
    for (final e in _game.lostPlayerNames.entries) {
      if (e.value == _game.myPeerId) {
        _game.rejoinAs(e.key);
        return;
      }
    }
    while (true) {
      final name = await RejoinNameSelectDialog.show(
          context, _game.lostPlayerNames.keys.toList());
      if (name == "asAudience") {
        _setMyName(asAudience: true);
        return;
      }
      if (name != null) {
        _game.rejoinAs(name);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint(debugDescribeFocusTree());
    // debugPrint(debugDescribeFocusTree());

    if (_imageMap.isEmpty) {
      return buildWaitingView("Loading images.");
    }
    if (_game.state == game.GameState.onCreatingMyPeer) {
      return buildWaitingView("Creating my peer.");
    }
    if (_game.state == game.GameState.onJoiningRoom) {
      return buildWaitingView("Creating a game room.");
    }
    if (_game.state == game.GameState.onSettingMyName) {
      return buildWaitingView("Setting my player name.");
    }
    if (_game.state == game.GameState.onWaitingOtherPlayersForStart) {
      return buildWaitingView("他のプレイヤーを待っています。");
    }
    if (_game.state == game.GameState.onWaitingOtherPlayersInGame) {
      final subtext = _game.lostPlayerNames.keys.toList().join(" と ");
      return buildWaitingView("${subtext}の接続が切れました。再接続を待っています。");
    }
    if (_game.table.playerDataMap.length != 4) {
      return buildWaitingView("Waiting data creation.");
    }
    if (window.innerWidth == null) {
      return buildWaitingView("Waiting data creation.");
    } else {
      final width = window.innerWidth!;
      final scale = width > baseTableSize ? 1.0 : width / baseTableSize;
      return buildBody(scale);
    }
  }

  Widget buildWaitingView(String message) {
    final widgets = <Widget>[
      Stack(
        children: const [
          TopIcon(),
          CircularProgressIndicator(),
        ],
        alignment: Alignment.center,
      ),
      const SizedBox(
        height: 20,
      ),
      Text(message)
    ];

    widgets.add(Row(mainAxisSize: MainAxisSize.min, children: [
      ElevatedButton(
        child: Text(_game.enabledMic ? "マイクOff" : "マイクOn"),
        onPressed: _game.availableMic
            ? () {
                _game.setEnabledMic(!_game.enabledMic);
              }
            : null,
      ),
      const SizedBox(
        width: 10.0,
      ),
      ElevatedButton(
          child: const Text("チャット"),
          onPressed: () {
            showChatDialog();
          })
    ]));

    for (final i in _game.member.entries) {
      final peerId = i.key;
      final micOn = _game.membersAudioState[peerId] ?? false;
      widgets.add(Row(mainAxisSize: MainAxisSize.min, children: [
        VoicedIcon(
            peerId: peerId,
            streamController: _streamController,
            micOff: !micOn),
        Flexible(
            child: Text(
          "${i.value}が参加しました。",
          overflow: TextOverflow.clip,
        )),
      ]));
    }

    for (final i in _game.audienceMap.entries) {
      final peerId = i.key;
      final micOn = _game.membersAudioState[peerId] ?? false;
      widgets.add(Row(mainAxisSize: MainAxisSize.min, children: [
        VoicedIcon(
            peerId: peerId,
            streamController: _streamController,
            micOff: !micOn),
        Flexible(
            child: Text(
          "${i.value}が観戦者として参加しました。",
          overflow: TextOverflow.clip,
        )),
      ]));
    }

    return Column(children: widgets);
  }

  Widget buildBody(double scale) {
    final peerId = _game.isAudience ? _game.audienceAs : _game.myPeerId;
    final tableSize = baseTableSize * scale;
    final stacks = <Widget>[];
    stacks.add(GestureDetector(
        onTap: () {
          setState(() {
            showStageAndPlayerInfo = !showStageAndPlayerInfo;
          });
        },
        child: Container(
          color: Colors.teal,
          width: tableSize,
          height: tableSize,
          child: CustomPaint(
            painter: TablePainter(peerId, _game.table, _uiImageMap),
          ),
        )));

    if (showStageAndPlayerInfo) {
      for (final widget in buildPlayerStateTiles(peerId, tableSize, scale)) {
        stacks.add(widget);
      }
      stacks.add(Transform.translate(
          offset: const Offset(0, 40),
          child: StageInfoWidget(
            table: _game.table,
            imageMap: _imageMap,
          )));
    }

    print(
        "needToStartDiscardTimeAnimation: ${_needToStartDiscardTimeAnimation}");
    if (_needToStartDiscardTimeAnimation) {
      stacks.add(buildDiscardTileAnimation(peerId, tableSize, scale));
    }

    final widgets = <Widget>[
      AudienceVoiceIcons(
          gameController: _game, streamController: _streamController),
      Stack(
        children: stacks,
        alignment: Alignment.center,
      ),
      ActionsBarWidget(
          gameData: _game,
          imageMap: _imageMap,
          tableSize: tableSize,
          tappableTileScale: tappableTileScale,
          showChatDialog: showChatDialog)
    ];

    return Column(
      children: widgets,
    );
  }

  void onTileImageLoaded(
      Map<String, ui.Image> uiImageMap, Map<String, Image> imageMap) {
    setState(() {
      _uiImageMap.addAll(uiImageMap);
      _imageMap.addAll(imageMap);
    });
  }

  void onSkyWayError(String message) {
    showNotifyDialog(context, title: "SkyWayエラー", message: message);
  }

  void showChatDialog() {
    ChatDialog.showChatDialog(context, _game, _chatStreamController);
  }

  Widget buildDiscardTileAnimation(
      String myPeerId, double tableSize, double scale) {
    final playerOrder = _game.table.playerDataMap.keys.toList();
    final baseIndex = playerOrder.indexOf(myPeerId);
    var discardedPlayerIndex =
        playerOrder.indexOf(_game.table.lastDiscardedPlayerPeerID);
    if (discardedPlayerIndex < baseIndex) {
      discardedPlayerIndex += 4;
    }
    final direction = discardedPlayerIndex - baseIndex;

    final baseOffset = tableSize / 2 - tableSize / 4;
    final offsets = [
      Offset(0, baseOffset),
      Offset(baseOffset, 0),
      Offset(0, -baseOffset),
      Offset(-baseOffset, 0),
    ];

    final image = getTileImage(_game.table.lastDiscardedTile, direction);
    return Transform.translate(
        offset: offsets[direction],
        child: DiscardTileAnimation(
            image: image,
            listener: (status) {
              print("DiscardTileAnimation: ${status}");
              if (AnimationStatus.dismissed == status) {
                print("needToStartDiscardTimeAnimation: clear");
                _needToStartDiscardTimeAnimation = false;
              }
            }));
  }

  Image getTileImage(int tile, direction) {
    // direction = 0: 打牌(上向, 1: 打牌(左向, 2: 打牌(下向, 3: 打牌(右向, 4: 自牌(上向,
    final info = tbl.TileInfo(tile);
    final key = "${info.type}_${info.number}_${direction}";
    final image = _imageMap[key]!;
    return image;
  }

  List<Widget> buildPlayerStateTiles(
      String myPeerId, double tableSize, double scale) {
    final playerOrder = _game.table.playerDataMap.keys.toList();
    final baseIndex = playerOrder.indexOf(myPeerId);
    final leaderBaseIndex = _game.table.leaderChangeCount % 4;

    final winds = [
      "東",
      "南",
      "西",
      "北",
    ];
    final baseOffset = tableSize / 2 - scale * 35 - 30;
    final subOffset = scale * 20;
    final offsets = [
      Offset(0, baseOffset - subOffset),
      Offset(baseOffset, 0),
      Offset(0, -baseOffset),
      Offset(-baseOffset, 0),
    ];
    final angles = [
      0.0,
      -pi / 2,
      pi,
      pi / 2,
    ];

    final widgets = <Widget>[];
    for (int direction = 0; direction < 4; direction++) {
      final index = (direction + baseIndex) % 4;
      final leaderIndex = (4 + (index - leaderBaseIndex)) % 4;
      final peerId = playerOrder[index];
      final data = _game.table.playerDataMap[peerId]!;
      final turned = _game.table.turnedPeerId == peerId;
      final enabledAudio = _game.membersAudioState[peerId] ?? false;

      widgets.add(Transform.translate(
          offset: offsets[direction],
          child: Transform.rotate(
              angle: angles[direction],
              child: PlayerStateTile(
                  winds[leaderIndex],
                  data.name,
                  data.score,
                  data.existRiichiBar,
                  turned,
                  peerId,
                  _streamController,
                  !enabledAudio))));
    }

    return widgets;
  }
}

class TablePainter extends CustomPainter {
  TablePainter(this._myPeerId, this._tableData, this._imageMap) {
    _tilesPainter = TilesPainter(_myPeerId, _tableData, _imageMap);
  }

  late TilesPainter _tilesPainter;
  final Map<String, ui.Image> _imageMap;
  final String _myPeerId;
  final tbl.Table _tableData;

  @override
  void paint(Canvas canvas, Size size) {
    _tilesPainter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
