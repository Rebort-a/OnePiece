import 'package:flutter/material.dart';

import 'network_engine.dart';
import '../network/network_message.dart';
import '../network/network_room.dart';
import '../utils/custom_notifier.dart';
import '../game/gamer.dart';
import '../game/step.dart';

class NetTurnEngine {
  final ValueNotifier<TurnGameStep> gameStep = ValueNotifier(
    TurnGameStep.disconnect,
  );

  late final GamerType playerType;
  late final int enemyIdentify;
  late final NetworkEngine networkEngine;

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator;
  final void Function() searchHandler;
  final void Function(TurnGameStep, NetworkMessage) resourceHandler;
  final void Function(bool, NetworkMessage) actionHandler;

  NetTurnEngine({
    required String userName,
    required RoomInfo roomInfo,
    required this.pageNavigator,
    required this.searchHandler,
    required this.resourceHandler,
    required this.actionHandler,
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
    // 先手和后手都会处理，使得状态更新为connected
    // 获取服务器连接消息后，更新游戏阶段到连接状态，同时查找对手
    if (gameStep.value == TurnGameStep.disconnect) {
      gameStep.value = TurnGameStep.connected;
      networkEngine.sendNetworkMessage(
        MessageType.search,
        'Searching for opponent',
      );
    }
  }

  void _handleSearchMessage(NetworkMessage message) {
    // 只有先手才能获得非自身发出的SearchMessage
    // 如果在连接状态下，收到他人查找对手的消息，那么直接匹配到对手，确定自身为先手，更新游戏状态到先手配置阶段，同时向对手发送匹配成功的信息
    // 然后有两种选择，要么界面上根据游戏阶段，出现配置按钮，点击后生成棋牌，要么直接生成棋牌，进入下一个阶段，我们选择后者
    if (gameStep.value == TurnGameStep.connected &&
        message.id != networkEngine.identify) {
      enemyIdentify = message.id;
      networkEngine.sendNetworkMessage(MessageType.match, 'Match to opponent');
      playerType = GamerType.front;
      gameStep.value = TurnGameStep.frontConfig;
      searchHandler();
    }
  }

  void _handleMatchMessage(NetworkMessage message) {
    // 只有后手才会收到非自身发出的MatchMessage
    // 如果在连接状态下，收到对手匹配成功的消息，那么直接匹配到对手，确认自己为后手，进入后手等待先手配置阶段
    if (gameStep.value == TurnGameStep.connected &&
        message.id != networkEngine.identify) {
      enemyIdentify = message.id;
      playerType = GamerType.rear;
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
    // 2.在frontWait收到对手的配置信息，更新阶段到行动阶段，轮到自己行动
    if (gameStep.value == TurnGameStep.frontConfig && isSelf) {
      resourceHandler(TurnGameStep.frontConfig, message);
      gameStep.value = TurnGameStep.frontWait;
    } else if (gameStep.value == TurnGameStep.frontWait && isEnemy) {
      resourceHandler(TurnGameStep.frontWait, message);
      gameStep.value = TurnGameStep.action;
    } else
    // 后手
    // 1.在connected收到对手的配置信息，匹配对手，更新阶段到rearWait，等待对手配置完成，防止之前未匹配成功
    // 2.在rearWait收到对手的配置信息，更新阶段到rearWait，等待对手配置完成
    // 3.在rearConfig收到自己的信息，更新阶段到行动阶段，轮到对方行动
    if (gameStep.value == TurnGameStep.connected && !isSelf) {
      enemyIdentify = message.id;

      resourceHandler(TurnGameStep.connected, message);

      gameStep.value = TurnGameStep.rearConfig;
      networkEngine.sendNetworkMessage(MessageType.resource, "ok");
    } else if (gameStep.value == TurnGameStep.rearWait && isEnemy) {
      resourceHandler(TurnGameStep.rearWait, message);

      gameStep.value = TurnGameStep.rearConfig;
      networkEngine.sendNetworkMessage(MessageType.resource, "ok");
    } else if (gameStep.value == TurnGameStep.rearConfig && isSelf) {
      resourceHandler(TurnGameStep.rearConfig, message);
      gameStep.value = TurnGameStep.action;
    }
  }

  void _handleActionMessage(NetworkMessage message) {
    bool isSelf =
        message.id == networkEngine.identify &&
        message.source == networkEngine.userName;

    bool isEnemy = message.id == enemyIdentify;

    if (!isSelf && !isEnemy) {
      return;
    }

    actionHandler(isSelf, message);
  }
}
