import 'dart:async';
import 'dart:convert';
import 'wrapper.dart' as wrapper;

enum CommandResultStateCode {
  ok,
  refuse,
  error,
}

class CommandResult {
  CommandResult(this.state, this.message);

  factory CommandResult.fromJsonMap(Map<String, dynamic> map) {
    final stateIndex = map["state"] as int;
    final message = map["message"] as String;
    final state = CommandResultStateCode.values[stateIndex];
    return CommandResult(state, message);
  }

  final CommandResultStateCode state;
  final String message;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{"state": state.index, "message": message};
  }
}

class CommandHandler {
  final _completerMap = <int, Completer<CommandResult>>{};

  Future<CommandResult> sendCommand(
      String commanderPeerId, Map<String, dynamic> command) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tmp = <String, dynamic>{
      "type": "command",
      "commander": commanderPeerId,
      "commandTimestamp": timestamp,
    };
    tmp.addAll(command);
    final completer = Completer<CommandResult>();
    _completerMap[timestamp] = completer;
    wrapper.sendData(jsonEncode(tmp));
    return completer.future;
  }

  void sendCommandResult(
      Map<String, dynamic> commandData, CommandResult result) {
    final tmp = <String, dynamic>{
      "type": "commandResult",
      "commander": commandData["commander"]!,
      "commandTimestamp": commandData["commandTimestamp"]!,
      "resultTimestamp": DateTime.now().millisecondsSinceEpoch,
      "result": result.toMap(),
    };
    wrapper.sendData(jsonEncode(tmp));
  }

  void onReceiveCommandResult(Map<String, dynamic> data, String myPeerId) {
    final peerId = data["commander"] as String;
    if (peerId != myPeerId) return;
    final commandTimestamp = data["commandTimestamp"] as int;
    final resultTimestamp = data["resultTimestamp"] as int;
    final resultJsonMap = jsonDecode(data["result"]) as Map<String, dynamic>;
    final result = CommandResult.fromJsonMap(resultJsonMap);

    final completer = _completerMap[commandTimestamp];
    if (completer != null) completer.complete(result);
  }
}
