import 'dart:convert';
import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import '../00.common/engine/net_turn_engine.dart';
import '../00.common/game/step.dart';
import '../00.common/network/network_message.dart';
import '../00.common/network/network_room.dart';

import 'extension.dart';
import 'foundation_manager.dart';

class NetAnimalChessManager extends BaseManager {
  late final NetTurnEngine netTurnEngine;

  NetAnimalChessManager({
    required String userName,
    required RoomInfo roomInfo,
  }) {
    // 使用局部函数初始化NetTurnEngine
    netTurnEngine = NetTurnEngine(
      userName: userName,
      roomInfo: roomInfo,
      pageNavigator: pageNavigator,
      searchHandler: _searchHandler,
      resourceHandler: _resourceHandler,
      actionHandler: _actionHandler,
    );
  }

  // 定义局部函数 - 搜索处理
  void _searchHandler() {
    initializeGame(); // 这个时候我们直接生成棋牌
    netTurnEngine.networkEngine.sendNetworkMessage(
      MessageType.resource,
      _mapToString(),
    ); // 然后通过网络发送
  }

  // 定义局部函数 - 资源处理
  void _resourceHandler(TurnGameStep step, NetworkMessage message) {
    if (step == TurnGameStep.connected || step == TurnGameStep.rearConfig) {
      _stringToMap(message.content);
    }
  }

  // 定义局部函数 - 动作处理
  void _actionHandler(bool isSelf, NetworkMessage message) {
    int index = jsonDecode(message.content)['index'];
    if (index < 0 || index >= displayMap.length) {
      //对方逃跑
      if (!isSelf) {
        showChessResult(netTurnEngine.playerType == GamerType.front);
      }
      return;
    }

    if (netTurnEngine.gameStep.value == TurnGameStep.action) {
      if (currentGamer.value == netTurnEngine.playerType && isSelf) {
        selectGrid(index);
      } else if (!isSelf) {
        selectGrid(index);
      }
    }
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
    if ((netTurnEngine.gameStep.value == TurnGameStep.action &&
            currentGamer.value == netTurnEngine.playerType) ||
        index == -1) {
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
  void leaveRoom() {
    netTurnEngine.networkEngine.leavePage();
  }

  void surrender() {
    sendActionMessage(-1); // 发送投降消息
    showChessResult(netTurnEngine.playerType == GamerType.rear); //显示游戏结果
  }

  void exitRoom() {
    netTurnEngine.networkEngine.leavePage();
  }
}
