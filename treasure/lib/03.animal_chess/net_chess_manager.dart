import 'dart:convert';
import 'package:flutter/material.dart';

import '../00.common/engine/network_engine.dart';
import '../00.common/game/gamer.dart';
import '../00.common/game/step.dart';
import '../00.common/network/network_message.dart';
import '../00.common/network/network_room.dart';

import 'extension.dart';
import 'foundation_manager.dart';

class NetAnimalChessManager extends BaseManager {
  final ValueNotifier<TurnGameStep> gameStep = ValueNotifier(
    TurnGameStep.disconnect,
  );

  late final GamerType selfType;
  late final int enemyIdentify;

  late final NetworkEngine networkEngine;

  NetAnimalChessManager({
    required String userName,
    required RoomInfo roomInfo,
  }) {
    networkEngine = NetworkEngine(
      userName: userName,
      roomInfo: roomInfo,
      navigatorHandler: pageNavigator,
      messageHandler: _handleMessage,
    );
  }

  void _handleMessage(NetworkMessage message) {
    switch (message.type) {
      case MessageType.accept:
        _handleAcceptMessage(message);
        break;
      case MessageType.search:
        _handleSearchMessage(message);
        break;
      case MessageType.match:
        _handleMatchMessage(message);
        break;
      case MessageType.resource:
        _handleResourceMessage(message);
        break;
      case MessageType.action:
        _handleActionMessage(message);
        break;
      default:
        break;
    }
  }

  void _handleAcceptMessage(NetworkMessage message) {
    // 获取服务器连接消息后，更新游戏阶段到连接状态，同时查找对手
    // 尚未确定先后手
    if (gameStep.value == TurnGameStep.disconnect) {
      gameStep.value = TurnGameStep.connected;
      networkEngine.sendNetworkMessage(
        MessageType.search,
        'Searching for opponent',
      );
    }
  }

  void _handleSearchMessage(NetworkMessage message) {
    // 如果在连接状态下，收到他人查找对手的消息，那么直接匹配到对手，确定自身为先手，更新游戏状态到先手配置阶段，同时向对手发送匹配成功的信息
    // 然后有两种选择，要么界面上根据游戏阶段，出现配置按钮，点击后生成棋牌，要么直接生成棋牌，进入下一个阶段，我们选择后者
    // 先手
    if (gameStep.value == TurnGameStep.connected &&
        message.id != networkEngine.identify) {
      enemyIdentify = message.id;
      networkEngine.sendNetworkMessage(MessageType.match, 'Match to opponent');
      selfType = GamerType.front;
      gameStep.value = TurnGameStep.frontConfig;
      initializeGame(); // 这个时候我们直接生成棋牌
      networkEngine.sendNetworkMessage(
        MessageType.resource,
        _mapToString(),
      ); // 然后通过网络发送
    }
  }

  void _handleMatchMessage(NetworkMessage message) {
    // 如果在连接状态下，收到对手匹配成功的消息，那么直接匹配到对手，确认自己为后手，进入等待先手配置阶段
    // 后手
    if (gameStep.value == TurnGameStep.connected &&
        message.id != networkEngine.identify) {
      enemyIdentify = message.id;
      selfType = GamerType.rear;
      gameStep.value = TurnGameStep.rearWait;
    }
  }

  void _handleResourceMessage(NetworkMessage message) {
    bool isSelf =
        message.id == networkEngine.identify &&
        message.source == networkEngine.userName;
    bool isEnemy = message.id == enemyIdentify;

    // 先手
    // 1.在frontConfig收到自己的信息，更新阶段到frontWait，等待对手配置完成
    // 2.在frontWait收到对手的配置信息(实际仅是回应)，更新阶段到行动阶段，轮到自己行动
    if (gameStep.value == TurnGameStep.frontConfig && isSelf) {
      gameStep.value = TurnGameStep.frontWait;
    } else if (gameStep.value == TurnGameStep.frontWait && isEnemy) {
      gameStep.value = TurnGameStep.action;
    } else
    // 后手
    // 1.在connected收到对手的配置信息，匹配对手，更新阶段到rearWait，等待对手配置完成，防止之前未匹配成功
    // 2.在rearWait收到对手的配置信息，更新阶段到rearWait，等待对手配置完成
    // 3.在rearConfig收到自己的信息(实际仅是回应)，更新阶段到行动阶段，轮到对方行动
    if (gameStep.value == TurnGameStep.connected && !isSelf) {
      enemyIdentify = message.id;
      _stringToMap(message.content);
      gameStep.value = TurnGameStep.rearConfig;
      networkEngine.sendNetworkMessage(MessageType.resource, "ok");
    } else if (gameStep.value == TurnGameStep.rearWait && isEnemy) {
      _stringToMap(message.content);
      gameStep.value = TurnGameStep.rearConfig;
      networkEngine.sendNetworkMessage(MessageType.resource, "ok");
    } else if (gameStep.value == TurnGameStep.rearConfig && isSelf) {
      gameStep.value = TurnGameStep.action;
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
    if ((gameStep.value == TurnGameStep.action &&
        currentGamer.value == selfType)) {
      networkEngine.sendNetworkMessage(
        MessageType.action,
        jsonEncode({'index': index}),
      );
    }
  }

  void _handleActionMessage(NetworkMessage message) {
    int index = jsonDecode(message.content)['index'];

    bool isSelf =
        message.id == networkEngine.identify &&
        message.source == networkEngine.userName;
    bool isEnemy = message.id == enemyIdentify;

    if (index < 0 || index >= displayMap.length) {
    } else if (gameStep.value == TurnGameStep.action) {
      if (currentGamer.value == selfType && isSelf) {
        selectGrid(index);
      } else if (isEnemy) {
        selectGrid(index);
      }
    }
  }

  @override
  List<Widget> buildDialogActions(BuildContext context) {
    return [
      TextButton(
        child: const Text('退出'),
        onPressed: () {
          Navigator.of(context).pop();
          networkEngine.leavePage();
        },
      ),
    ];
  }

  @override
  void leaveChess() {
    showChessResult(currentGamer.value == GamerType.rear);
  }
}
