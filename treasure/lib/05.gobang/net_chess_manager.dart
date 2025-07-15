// net_chess_manager.dart
import 'dart:convert';

import 'package:flutter/material.dart';

import '../00.common/engine/net_turn_engine.dart';
import '../00.common/game/step.dart';
import '../00.common/model/notifier.dart';
import '../00.common/network/network_message.dart';
import '../00.common/network/network_room.dart';
import 'foundation_manager.dart';

class NetGomokuManager extends BaseGomokuManager {
  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});
  late final NetTurnGameEngine netTurnEngine;

  NetGomokuManager({required String userName, required RoomInfo roomInfo}) {
    netTurnEngine = NetTurnGameEngine(
      userName: userName,
      roomInfo: roomInfo,
      navigatorHandler: pageNavigator,
      searchHandler: _searchHandler,
      resourceHandler: _resourceHandler,
      actionHandler: _actionHandler,
      endHandler: _endHandler,
    );
  }

  void _searchHandler() {
    netTurnEngine.sendNetworkMessage(MessageType.resource, 'ok');
  }

  void _resourceHandler(GameStep step, NetworkMessage message) {
    if (step == GameStep.connected || step == GameStep.rearWait) {
      netTurnEngine.sendNetworkMessage(MessageType.resource, 'ok');
    } else if (step == GameStep.frontWait) {
      board.restart();
    } else if (step == GameStep.rearConfig) {
      board.restart();
    }
  }

  void _actionHandler(bool isSelf, NetworkMessage message) {
    final data = jsonDecode(message.content);
    int index = data['index'];

    board.placePiece(index);
  }

  @override
  void placePiece(int index) {
    if (board.currentGamer.value == netTurnEngine.playerType) {
      netTurnEngine.sendNetworkMessage(
        MessageType.action,
        jsonEncode({'index': index}),
      );
    }
  }

  void _endHandler() {
    // 处理游戏结束
  }
}
