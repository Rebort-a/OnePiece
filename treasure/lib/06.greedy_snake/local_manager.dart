import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../00.common/model/notifier.dart';
import 'base.dart';

class BaseManager extends ChangeNotifier {
  final Random _random = Random();

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});
  final Map<int, Snake> snakes = {}; // 保存所有蛇，第一个是玩家
  final List<Food> foods = []; // 保存所有食物

  // 游戏计时器
  late final Ticker _ticker;
  double _foodCheckAccumulator = 0;

  int identity = 0; // 玩家标识

  BaseManager() {
    _initGmae();
    _startGameLoop();
  }

  void _initGmae() {
    snakes[identity] = _createSnake(); // 初始化玩家

    // 初始化5个随机敌人蛇和食物
    for (int i = 1; i <= 5; i++) {
      snakes[identity + i] = _createSnake();
      foods.add(Food(position: _getRandomPosition()));
    }
  }

  Snake _createSnake() {
    return Snake(
      head: _getRandomPosition(),
      length: _getRandomLength(),
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

  int _getRandomLength() {
    if (snakes.isNotEmpty) {
      return _random.nextInt(snakes.values.first.length) + 30;
    }
    return _random.nextInt(70) + 30;
  }

  double _getRandomAngle() {
    return _random.nextDouble() * 2 * pi;
  }

  // 开始游戏循环
  void _startGameLoop() {
    _ticker = Ticker(_gameLoopCallback);
    _ticker.start();
  }

  // 游戏循环回调
  void _gameLoopCallback(Duration elapsed) {
    double deltaTime = min(elapsed.inMilliseconds / 1000.0, 0.1); // 限制最大时间步

    snakes.forEach((id, snake) {
      snake.updatePosition(deltaTime);
    });

    // 处理碰撞事件
    _handleCollisions();

    _foodCheckAccumulator += deltaTime;

    if (_foodCheckAccumulator > 0.2) {
      // 敌人每隔200毫秒，会朝最近的食物转向
      snakes.forEach((id, snake) {
        if (id == identity) {
          return;
        }

        _turnToFood(snake);
      });
    }

    notifyListeners(); // 更新UI
  }

  void _turnToFood(Snake snake) {
    Offset nearestFood = _getNearestFood(snake.head);
    if (nearestFood != Offset.zero) {
      double dx = nearestFood.dx - snake.head.dx;
      double dy = nearestFood.dy - snake.head.dy;
      double newAngle = atan2(dy, dx);
      snake.updateAngle(newAngle);
    }
  }

  // 获取最近的食物
  Offset _getNearestFood(Offset position) {
    if (foods.isEmpty) return Offset.zero;
    Food nearest = foods.first;
    double minDistance = (position - nearest.position).distance;
    for (Food food in foods) {
      double distance = (position - food.position).distance;
      if (distance < minDistance) {
        minDistance = distance;
        nearest = food;
      }
    }
    return nearest.position;
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
        if (id == identity) {
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
            foodSize / 2 + snake.style.headSize / 2 + 10) {
          snake.updateLength(snakeGrowthPerFood.toInt());
          foods.removeAt(i);
          foods.add(Food(position: _getRandomPosition())); // 生成新食物
          break; // 一次只能吃一个食物
        }
      }

      // 3. 其他蛇碰撞检测
      for (final otherId in snakes.keys) {
        if (id == otherId) continue;

        final otherSnake = snakes[otherId]!;
        for (final bodyPart in otherSnake.body) {
          if ((snake.head - bodyPart).distance <
              snake.style.headSize / 2 + snake.style.headSize / 2) {
            if (id == identity) {
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
      snakes[id] = _createSnake(); // 重新生成蛇
    }
  }

  void _handleGameOver() {
    _ticker.stop();
    pageNavigator.value = (context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("游戏结束"),
            content: Text("最终长度: ${snakes[0]!.length}"),
            actions: [
              TextButton(
                child: const Text('确定'),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  _navigateToBack();
                },
              ),
            ],
          );
        },
      );
    };
  }

  void _navigateToBack() {
    pageNavigator.value = (context) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }

  void updatePlayerAngle(double newAngle) {
    if (snakes.isNotEmpty) {
      snakes.values.first.updateAngle(newAngle);
    }
  }

  void updatePlayerSpeed(bool isFaster) {
    if (snakes.isNotEmpty) {
      snakes.values.first.updateSpeed(isFaster);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
