// net_manager.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../00.common/engine/net_real_engine.dart';
import '../00.common/game/step.dart';
import '../00.common/model/notifier.dart';
import '../00.common/network/network_message.dart';
import '../00.common/network/network_room.dart';
import 'base.dart';

class NetManager extends ChangeNotifier {
  static const int generateCount = 10;
  final _random = Random();
  final pageNavigator = AlwaysNotifier<void Function(BuildContext)>((_) {});

  final snakes = <int, Snake>{};
  final foods = <Food>[];

  late final Ticker _ticker;
  late final NetRealGameEngine engine;

  NetManager({required String userName, required RoomInfo roomInfo}) {
    engine = NetRealGameEngine(
      userName: userName,
      roomInfo: roomInfo,
      navigatorHandler: pageNavigator,
      searchHandler: _handleSearch,
      resourceHandler: _handleResource,
      actionHandler: _handleAction,
      endHandler: _handleEnd,
    );
    _ticker = Ticker(_gameLoop);
  }

  void _handleSearch(int id) {
    if (snakes.isEmpty) snakes[engine.identity] = _createSnake();

    if (foods.isEmpty) {
      foods.addAll(
        List.generate(generateCount, (_) => Food(position: _randomPosition)),
      );
    }

    if (!snakes.containsKey(id)) {
      snakes[id] = _createSnake();
    }

    engine.sendNetworkMessage(MessageType.resource, _toJsonString());
  }

  Snake _createSnake() => Snake(
    head: _randomPosition,
    length: 100,
    angle: _randomAngle,
    style: SnakeStyle.random(),
  );

  Offset get _randomPosition => Offset(
    _random.nextDouble() * (mapWidth - 200) + 100,
    _random.nextDouble() * (mapHeight - 200) + 100,
  );

  double get _randomAngle => _random.nextDouble() * 2 * pi;

  void _handleResource(NetworkMessage message) {
    if (_ticker.isActive) _ticker.stop();
    _fromJsonString(message.content);
    _ticker.start();
  }

  void _gameLoop(Duration elapsed) {
    final deltaTime = min(elapsed.inMilliseconds / 1000.0, 0.1);
    for (var snake in snakes.values) {
      snake.updatePosition(deltaTime);
    }
    _handleCollisions();
    notifyListeners();
  }

  void _handleCollisions() {
    final toRemove = <int>{};

    for (final entry in snakes.entries) {
      final id = entry.key;
      final snake = entry.value;

      // Wall collision
      if (snake.head.dx < 0 ||
          snake.head.dx > mapWidth ||
          snake.head.dy < 0 ||
          snake.head.dy > mapHeight) {
        if (id == engine.identity) {
          _handleGameOver();
        } else {
          toRemove.add(id);
        }
        continue;
      }

      // Food collision
      for (int i = foods.length - 1; i >= 0; i--) {
        final food = foods[i];
        if ((snake.head - food.position).distance <
            Food.size / 2 + snake.style.headSize / 2 + 10) {
          snake.updateLength(Food.growthPerFood);
          foods.removeAt(i);
          break;
        }
      }

      // Snake collision
      for (final other in snakes.entries) {
        if (id == other.key) continue;

        for (final bodyPart in other.value.body) {
          if ((snake.head - bodyPart).distance <
              snake.style.headSize / 2 + snake.style.headSize / 2) {
            if (id == engine.identity) {
              _handleGameOver();
            } else {
              toRemove.add(id);
            }
            break;
          }
        }
      }
    }

    toRemove.forEach(snakes.remove);
  }

  void _handleGameOver() {
    _ticker.stop();
    engine.gameStep.value = GameStep.gameOver;
    pageNavigator.value = (context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("游戏结束"),
          content: Text("最终长度: ${snakes[engine.identity]?.length}"),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ).then((_) => _navigateBack());
    };
  }

  void _navigateBack() =>
      pageNavigator.value = (context) => Navigator.of(context).pop();

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

  void updatePlayerAngle(double angle) => engine.sendNetworkMessage(
    MessageType.action,
    json.encode({'actionType': 'joystick', 'angle': angle}),
  );

  void updatePlayerSpeed(bool isFaster) => engine.sendNetworkMessage(
    MessageType.action,
    json.encode({'actionType': 'speedButton', 'isFaster': isFaster}),
  );

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

  void _handleEnd() {}
  void leavePage() => engine.leavePage();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
