import 'package:flutter/material.dart';

import 'network_engine.dart';
import '../network/network_message.dart';
import '../game/step.dart';

class NetRealGameEngine extends NetworkEngine {
  final ValueNotifier<GameStep> gameStep = ValueNotifier(GameStep.disconnect);

  int _publisherId = 0;

  final void Function(int) searchHandler;
  final void Function(NetworkMessage) resourceHandler;
  final void Function(NetworkMessage) actionHandler;
  final void Function() endHandler;

  NetRealGameEngine({
    required super.userName,
    required super.roomInfo,
    required super.navigatorHandler,
    required this.searchHandler,
    required this.resourceHandler,
    required this.actionHandler,
    required this.endHandler,
  }) {
    super.messageHandler = _handleMessage;
  }

  void _handleMessage(NetworkMessage message) {
    switch (message.type) {
      case MessageType.accept:
        _handleAcceptMessage(message);
        break;
      case MessageType.search:
        _handleSearchMessage(message);
        break;
      case MessageType.resource:
        _handleResourceMessage(message);
        break;
      case MessageType.action:
        _handleActionMessage(message);
        break;
      case MessageType.exit:
        _handleExitMessage(message);
        break;
      case MessageType.match:
        _handleMatchMessage(message.id);
        break;
      default:
        break;
    }
  }

  void _handleAcceptMessage(NetworkMessage message) {
    if (gameStep.value == GameStep.disconnect) {
      gameStep.value = GameStep.connected;
      _publisherId = identity; // 先假定房间内没人，自己就是发布者
      sendNetworkMessage(MessageType.search, 'Searching for publisher');
    }
  }

  void _handleSearchMessage(NetworkMessage message) {
    if (message.id != identity) {
      // 收到他人的查找消息
      if (identity == _publisherId) {
        // 如果自己就是发布者，发布资源
        searchHandler(message.id);
      }
    }
  }

  void _handleResourceMessage(NetworkMessage message) {
    _handleMatchMessage(message.id);
    resourceHandler(message);
    gameStep.value = GameStep.action;
  }

  void _handleActionMessage(NetworkMessage message) {
    _handleMatchMessage(message.id);
    if (gameStep.value == GameStep.action) {
      actionHandler(message);
    }
  }

  void _handleExitMessage(NetworkMessage message) {
    if (message.id == _publisherId) {
      _publisherId = 0;
      sendNetworkMessage(MessageType.match, 'Election publisher');
    }
  }

  void _handleMatchMessage(int messageId) {
    if (_publisherId == 0) {
      _publisherId = messageId;
    } else if (messageId < _publisherId) {
      _publisherId = messageId;
    }
  }
}
