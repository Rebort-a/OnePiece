import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../00.common/model/notifier.dart';
import 'base.dart';

class BaseManager extends ChangeNotifier {
  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});
  final Map<int, Snake> snakes = {}; // 保存所有蛇，第一个是玩家
  final List<Food> foods = []; // 保存所有食物
  final Random _random = Random();

  // 游戏计时器
  late final Ticker _ticker;
  int _tickCount = 0;

  BaseManager() {
    _initGmae();
    _startGameLoop();
  }

  void _initGmae() {
    snakes[0] = _createSnake(); // 初始化玩家

    // 初始化5个随机敌人蛇和食物
    for (int i = 1; i <= 5; i++) {
      snakes[i] = _createSnake();
      foods.add(Food(position: _getRandomPosition(_random)));
    }
  }

  // 开始游戏循环
  void _startGameLoop() {
    _ticker = Ticker(_gameLoopCallback);
    _ticker.start();
  }

  // 游戏循环回调
  void _gameLoopCallback(Duration elapsed) {
    _tickCount++;

    snakes.forEach((id, snake) {
      snake.updatePosition(0.04);
    });

    // 处理碰撞事件
    _handleCollisions();

    if (_tickCount % 1000 == 0) {
      snakes.forEach((id, snake) {
        if (id == 0) {
          return;
        }

        Food? nearestFood = _getNearestFood(snake.head);
        if (nearestFood != null) {
          double dx = nearestFood.position.dx - snake.head.dx;
          double dy = nearestFood.position.dy - snake.head.dy;
          double newAngle = atan2(dy, dx);
          snake.updateAngle(newAngle);
        }
      });
    }

    notifyListeners(); // 更新UI
  }

  static Snake _createSnake() {
    Random random = Random();
    return Snake(
      head: _getRandomPosition(random),
      length: _getRandomLength(random),
      angle: _getRandomAngle(random),
    );
  }

  static Offset _getRandomPosition(Random random) {
    double safeWidth = mapWidth - 200;
    double safeHeight = mapHeight - 200;

    // 在安全区域内生成随机坐标
    double x = random.nextDouble() * safeWidth + 100;
    double y = random.nextDouble() * safeHeight + 100;

    return Offset(x, y);
  }

  static double _getRandomLength(Random random) {
    return random.nextInt(70) + 30;
  }

  static double _getRandomAngle(Random random) {
    return random.nextDouble() * 2 * pi;
  }

  // 获取最近的食物
  Food? _getNearestFood(Offset position) {
    if (foods.isEmpty) return null;
    Food nearest = foods[0];
    double minDistance = (position - nearest.position).distance;
    for (Food food in foods) {
      double distance = (position - food.position).distance;
      if (distance < minDistance) {
        minDistance = distance;
        nearest = food;
      }
    }
    return nearest;
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
        if (id == 0) {
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
            foodSize / 2 + snakeHeadSize / 2) {
          snake.updateLength(snakeGrowthPerFood.toInt());
          foods.removeAt(i);
          foods.add(Food(position: _getRandomPosition(_random))); // 生成新食物
          break; // 一次只能吃一个食物
        }
      }

      // 3. 其他蛇碰撞检测
      for (final otherId in snakes.keys) {
        if (id == otherId) continue;

        final otherSnake = snakes[otherId]!;
        for (final bodyPart in otherSnake.body) {
          if ((snake.head - bodyPart).distance <
              snakeHeadSize / 2 + snakeBodySize / 2) {
            if (id == 0) {
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

  _handleGameOver() {
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
}
