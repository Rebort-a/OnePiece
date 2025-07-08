import 'package:flutter/material.dart';

import 'network_engine.dart';
import '../network/network_message.dart';
import '../network/network_room.dart';
import '../model/notifier.dart';
import '../game/gamer.dart';
import '../game/step.dart';

class NetTurnGameEngine {
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
  final void Function() endHandler;

  NetTurnGameEngine({
    required String userName,
    required RoomInfo roomInfo,
    required this.pageNavigator,
    required this.searchHandler,
    required this.resourceHandler,
    required this.actionHandler,
    required this.endHandler,
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
      case MessageType.end:
        _handleEndMessage(message);
        break;
      default:
        break;
    }
  }

  void _handleAcceptMessage(NetworkMessage message) {
    // 先手和后手都会处理
    // 获取服务器连接消息后，更新游戏阶段到connected，同时查找对手
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
    // 然后有两种选择，要么界面上根据游戏阶段，出现配置按钮，点击后生成游戏资源，要么直接生成游戏资源，取决于searchHandler
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
      gameStep.value = TurnGameStep.frontWait;
      resourceHandler(TurnGameStep.frontConfig, message);
    } else if (gameStep.value == TurnGameStep.frontWait && isEnemy) {
      gameStep.value = TurnGameStep.action;
      resourceHandler(TurnGameStep.frontWait, message);
    } else
    // 后手
    // 1.在connected收到对手的配置信息，匹配对手，更新阶段到rearWait，等待对手配置完成，防止之前未匹配成功
    // 2.在rearWait收到对手的配置信息，更新阶段到rearWait，等待对手配置完成
    // 3.在rearConfig收到自己的信息，更新阶段到行动阶段，轮到对方行动
    if (gameStep.value == TurnGameStep.connected && !isSelf) {
      enemyIdentify = message.id;
      playerType = GamerType.rear;
      gameStep.value = TurnGameStep.rearConfig;
      resourceHandler(TurnGameStep.connected, message);
    } else if (gameStep.value == TurnGameStep.rearWait && isEnemy) {
      gameStep.value = TurnGameStep.rearConfig;
      resourceHandler(TurnGameStep.rearWait, message);
    } else if (gameStep.value == TurnGameStep.rearConfig && isSelf) {
      gameStep.value = TurnGameStep.action;
      resourceHandler(TurnGameStep.rearConfig, message);
    }
  }

  void _handleActionMessage(NetworkMessage message) {
    bool isSelf =
        message.id == networkEngine.identify &&
        message.source == networkEngine.userName;

    bool isEnemy = message.id == enemyIdentify;

    if (isSelf || isEnemy) {
      // 处理敌人和自己的行动信息
      actionHandler(isSelf, message);
    }
  }

  void _handleEndMessage(NetworkMessage message) {
    bool isEnemy = message.id == enemyIdentify;

    if (isEnemy) {
      // 只处理敌人的结束信息，因为自己结束会直接退出
      endHandler();
    }
  }
}
