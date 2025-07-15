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
  static const int generateCount = 5;
  final Random _random = Random();
  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});

  Map<int, Snake> snakes = {}; // 保存所有蛇，第一个是玩家
  List<Food> foods = []; // 保存所有食物

  // 游戏计时器
  late final Ticker _ticker;

  late final NetRealGameEngine netRealEngine;

  NetManager({required String userName, required RoomInfo roomInfo}) {
    netRealEngine = NetRealGameEngine(
      userName: userName,
      roomInfo: roomInfo,
      navigatorHandler: pageNavigator,
      searchHandler: _searchHandler,
      resourceHandler: _resourceHandler,
      actionHandler: _actionHandler,
      endHandler: _endHandler,
    );
    _ticker = Ticker(_gameLoopCallback);
  }

  void _searchHandler(int id) {
    if (snakes.isEmpty) {
      snakes[netRealEngine.identity] = _createSnake();
    }

    if (foods.isEmpty) {
      for (int i = 0; i < generateCount; i++) {
        foods.add(Food(position: _getRandomPosition()));
      }
    }
    snakes[id] = _createSnake();
    netRealEngine.sendNetworkMessage(MessageType.resource, _toJsonString());
  }

  Snake _createSnake() {
    return Snake(
      head: _getRandomPosition(),
      length: 100,
      angle: _getRandomAngle(),
      style: SnakeStyle.random(),
    );
  }

  Offset _getRandomPosition() {
    double safeWidth = mapWidth - 200;
    double safeHeight = mapHeight - 200;

    // 在安全区域内生成随机坐标
    double x = _random.nextDouble() * safeWidth + 100;
    double y = _random.nextDouble() * safeHeight + 100;

    return Offset(x, y);
  }

  double _getRandomAngle() {
    return _random.nextDouble() * 2 * pi;
  }

  void _resourceHandler(NetworkMessage message) {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _fromJsonString(message.content);
    _ticker.start();
  }

  void _gameLoopCallback(Duration elapsed) {
    double deltaTime = min(elapsed.inMilliseconds / 1000.0, 0.1); // 限制最大时间步

    snakes.forEach((id, snake) {
      snake.updatePosition(deltaTime);
    });

    // 处理碰撞事件
    _handleCollisions();

    notifyListeners(); // 更新UI
  }

  // 处理碰撞事件
  void _handleCollisions() {
    final List<int> toRemove = []; // 存储需要删除的蛇ID

    snakes.forEach((id, snake) {
      // 1. 墙壁碰撞检测
      if (snake.head.dx < 0 ||
          snake.head.dx > mapWidth ||
          snake.head.dy < 0 ||
          snake.head.dy > mapHeight) {
        if (id == netRealEngine.identity) {
          _handleGameOver();
        } else {
          toRemove.add(id);
        }

        return;
      }

      // 2. 食物碰撞检测
      for (int i = foods.length - 1; i >= 0; i--) {
        final food = foods[i];
        if ((snake.head - food.position).distance <
            Food.foodSize / 2 + snake.style.headSize / 2 + 10) {
          snake.updateLength(Food.snakeGrowthPerFood);
          foods.removeAt(i);
          break;
        }
      }

      // 3. 其他蛇碰撞检测
      for (final otherId in snakes.keys) {
        if (id == otherId) continue;

        final otherSnake = snakes[otherId]!;
        for (final bodyPart in otherSnake.body) {
          if ((snake.head - bodyPart).distance <
              snake.style.headSize / 2 + snake.style.headSize / 2) {
            if (id == netRealEngine.identity) {
              _handleGameOver();
            } else if (!toRemove.contains(id)) {
              toRemove.add(id);
              break;
            }
          }
        }
      }
    });

    // 遍历结束后统一删除
    for (final id in toRemove) {
      snakes.remove(id);
    }
  }

  void _handleGameOver() {
    _ticker.stop();
    netRealEngine.gameStep.value = GameStep.gameOver;
    pageNavigator.value = (context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("游戏结束"),
            content: Text("最终长度: ${snakes[netRealEngine.identity]!.length}"),
            actions: [
              TextButton(
                child: const Text('确定'),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        },
      ).then((_) {
        _navigateToBack();
      });
    };
  }

  void _navigateToBack() {
    pageNavigator.value = (context) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }

  String _toJsonString() {
    return json.encode(_toJson());
  }

  void _fromJsonString(String jsonString) {
    _fromJson(json.decode(jsonString));
  }

  Map<String, dynamic> _toJson() {
    return {
      'snakes': snakes.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
      'foods': foods.map((food) => food.toJson()).toList(),
    };
  }

  void _fromJson(Map<String, dynamic> json) {
    snakes = <int, Snake>{};
    (json['snakes'] as Map<String, dynamic>).forEach((key, value) {
      snakes[int.parse(key)] = Snake.fromJson(value);
    });

    foods = (json['foods'] as List<dynamic>)
        .map((item) => Food.fromJson(item))
        .toList();
  }

  void updatePlayerAngle(double newAngle) {
    final content = json.encode({'actionType': 'joystick', 'angle': newAngle});
    netRealEngine.sendNetworkMessage(MessageType.action, content);
  }

  void updatePlayerSpeed(bool isFaster) {
    final content = json.encode({
      'actionType': 'speedButton',
      'isFaster': isFaster,
    });
    netRealEngine.sendNetworkMessage(MessageType.action, content);
  }

  void _actionHandler(NetworkMessage message) {
    final Map<String, dynamic> content = json.decode(message.content);
    final actionType = content['actionType'] as String;

    switch (actionType) {
      case 'joystick':
        final angle = content['angle'] as double;
        snakes[message.id]!.updateAngle(angle);
        break;
      case 'speedButton':
        final isFaster = content['isFaster'] as bool;
        snakes[message.id]!.updateSpeed(isFaster);
        break;
    }
  }

  void _endHandler() {}

  void leavePage() {
    netRealEngine.leavePage();
  }
}
