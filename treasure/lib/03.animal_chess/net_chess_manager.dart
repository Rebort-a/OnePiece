import 'dart:convert';
import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import '../00.common/engine/net_turn_engine.dart';
import '../00.common/game/step.dart';
import '../00.common/network/network_message.dart';
import '../00.common/network/network_room.dart';

import 'extension.dart';
import 'foundation_manager.dart';

class NetAnimalChessManager extends BaseAnimalChessManager {
  late final NetTurnGameEngine netTurnEngine;

  NetAnimalChessManager({
    required String userName,
    required RoomInfo roomInfo,
  }) {
    // 构建网络回合制游戏对战引擎
    netTurnEngine = NetTurnGameEngine(
      userName: userName,
      roomInfo: roomInfo,
      pageNavigator: pageNavigator,
      searchHandler: _searchHandler,
      resourceHandler: _resourceHandler,
      actionHandler: _actionHandler,
      endHandler: _endHandler,
    );
  }

  void _searchHandler() {
    initializeGame();
    netTurnEngine.networkEngine.sendNetworkMessage(
      MessageType.resource,
      _mapToString(),
    ); // 然后通过网络发送
  }

  void _resourceHandler(TurnGameStep step, NetworkMessage message) {
    if (step == TurnGameStep.connected || step == TurnGameStep.rearWait) {
      _stringToMap(message.content);
      netTurnEngine.networkEngine.sendNetworkMessage(
        MessageType.resource,
        "ok",
      );
    }
  }

  void _actionHandler(bool isSelf, NetworkMessage message) {
    if (netTurnEngine.gameStep.value == TurnGameStep.action) {
      int index = jsonDecode(message.content)['index'];
      if (index >= 0 && index < displayMap.length) {
        if (currentGamer.value == netTurnEngine.playerType && isSelf) {
          // 自己回合中，自己行动才能生效
          selectGrid(index);
        } else if (!isSelf) {
          // 敌人行为直接生效，然后回合会切换为自己回合
          selectGrid(index);
        }
      }
    }
  }

  void _endHandler() {
    showChessResult(netTurnEngine.playerType == GamerType.front);
  }

  String _mapToString() {
    return jsonEncode({
      '_boardSize': boardSize,
      'board': displayMap.value
          .map((notifier) => notifier.value.toJson())
          .toList(),
    });
  }

  void _stringToMap(String content) {
    final decodedContent = jsonDecode(content);
    boardSize = decodedContent['_boardSize'];

    // 将 JSON 数据转换为 GridNotifier 对象列表
    final boardData = decodedContent['board'] as List<dynamic>;
    final gridNotifiers = boardData.map((gridJson) {
      final grid = GridSerialization.fromJson(gridJson as Map<String, dynamic>);
      return GridNotifier(grid);
    }).toList();

    displayMap.value = gridNotifiers;
  }

  void sendActionMessage(int index) {
    if (netTurnEngine.gameStep.value == TurnGameStep.action &&
        currentGamer.value == netTurnEngine.playerType) {
      netTurnEngine.networkEngine.sendNetworkMessage(
        MessageType.action,
        jsonEncode({'index': index}),
      );
    }
  }

  @override
  void showChessResult(bool isRedWin) {
    netTurnEngine.gameStep.value = TurnGameStep.gamerOver;
    pageNavigator.value = (context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("游戏结束"),
            content: Text("${isRedWin ? "红" : "蓝"}方获胜！"),
            actions: [
              TextButton(
                child: const Text('退出'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ).then((_) {
        // 处理对话框关闭后的逻辑
        netTurnEngine.networkEngine.leavePage();
      });
    };
  }

  @override
  void leavePage() {
    netTurnEngine.networkEngine.leavePage();
  }

  void surrender() {
    netTurnEngine.networkEngine.sendNetworkMessage(
      MessageType.end,
      'give up',
    ); // 发送投降消息
    showChessResult(
      netTurnEngine.playerType == GamerType.rear,
    ); //直接显示游戏结果，不必等到服务器响应，防止网络异常时无法退出
  }

  void exitRoom() {
    netTurnEngine.networkEngine.leavePage();
  }
}
