import 'dart:convert';

import '../00.common/engine/net_real_engine.dart';
import '../00.common/network/network_message.dart';
import '../00.common/network/network_room.dart';
import 'base.dart';
import 'foundation_manager.dart';

class NetManager extends FoundationalManager {
  static const int generateCount = 10;

  int gamerCount = 0;

  late final NetRealGameEngine engine;

  NetManager({required String userName, required RoomInfo roomInfo}) {
    engine = NetRealGameEngine(
      userName: userName,
      roomInfo: roomInfo,
      navigatorHandler: pageNavigator,
      searchHandler: _handleSearch,
      resourceHandler: _handleResource,
      syncHandler: _handleSync,
      actionHandler: _handleAction,
      exitHandler: _handleEnd,
    );
    initTicker();
  }

  @override
  int get identity => engine.identity;

  void _handleSearch(int id) {
    if (snakes.isEmpty) {
      snakes[engine.identity] = createSnake(FoundationalManager.initialLength);
    }

    if (!snakes.containsKey(id)) {
      snakes[id] = createSnake(FoundationalManager.initialLength);
    }

    if (foods.isEmpty) {
      for (int i = 0; i < generateCount; i++) {
        createFood(randomPosition);
      }
    }

    engine.sendNetworkMessage(MessageType.resource, _toJsonString());
  }

  void _handleResource(NetworkMessage message) {
    suspendGame();
    _fromJsonString(message.content);
    gamerCount = snakes.length;

    engine.sendNetworkMessage(MessageType.sync, 'sync');
  }

  String _toJsonString() => json.encode(_toJson());
  void _fromJsonString(String jsonString) => _fromJson(json.decode(jsonString));

  Map<String, dynamic> _toJson() => {
    'snakes': snakes.map((k, v) => MapEntry(k.toString(), v.toJson())),
    'foods': foods.map((f) => f.toJson()).toList(),
  };

  void _fromJson(Map<String, dynamic> json) {
    snakes.clear();
    (json['snakes'] as Map<String, dynamic>).forEach((k, v) {
      snakes[int.parse(k)] = Snake.fromJson(v);
    });

    foods.clear();
    foods.addAll((json['foods'] as List).map((f) => Food.fromJson(f)));
  }

  void _handleSync(int id) {
    if (snakes.containsKey(id)) {
      gamerCount--;
      if (gamerCount <= 0) {
        resumeGame();
      }
    }
  }

  void _handleAction(NetworkMessage message) {
    final content = json.decode(message.content) as Map<String, dynamic>;
    final actionType = content['actionType'] as String;
    final snake = snakes[message.id];

    if (snake == null) return;

    switch (actionType) {
      case 'joystick':
        snake.updateAngle(content['angle'] as double);
        break;
      case 'speedButton':
        snake.updateSpeed(content['isFaster'] as bool);
        break;
    }
  }

  void _handleEnd(int id) {
    if (snakes.containsKey(id)) {
      snakes.remove(id);
    }
  }

  @override
  void updatePlayerAngle(double angle) => engine.sendNetworkMessage(
    MessageType.action,
    json.encode({'actionType': 'joystick', 'angle': angle}),
  );

  @override
  void updatePlayerSpeed(bool isFaster) => engine.sendNetworkMessage(
    MessageType.action,
    json.encode({'actionType': 'speedButton', 'isFaster': isFaster}),
  );

  @override
  void handleTickerCallback(double deltaTime) {}

  @override
  void handleRemoveSnakeCallback(int index) {}

  @override
  void leavePage() {
    engine.leavePage();
  }
}
