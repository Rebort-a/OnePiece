import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../00.common/model/notifier.dart';
import 'base.dart';

class NearestPoint {
  final int source;
  final Offset position;
  final double distance;

  NearestPoint({
    required this.source,
    required this.position,
    required this.distance,
  });
}

abstract class FoundationalManager extends ChangeNotifier {
  static const int initialLength = 100;
  final Random _random = Random();

  final Map<int, Snake> snakes = {};
  final Map<int, NearestPoint> _snakeCollision = {};
  final List<Food> foods = [];

  late final Ticker _ticker;
  double _lastElapsed = 0;

  final pageNavigator = AlwaysNotifier<void Function(BuildContext)>((_) {});
  final gameState = ValueNotifier<bool>(false);

  int get identity;

  void addSnake(int id, int length) {
    if (snakes.containsKey(id)) return;
    final snake = _createSnake(length);
    _updateSelfSnakeCollision(id, snake);
    snakes[id] = snake;
  }

  Snake _createSnake(int length) => Snake(
    head: randomSafePosition,
    length: _random.nextInt(length) + 30,
    angle: _random.nextDouble() * 2 * pi,
    style: SnakeStyle.random(),
  );

  Offset get randomSafePosition => Offset(
    _random.nextDouble() * (mapWidth - initialLength * 2) + initialLength,
    _random.nextDouble() * (mapHeight - initialLength * 2) + initialLength,
  );

  bool isInSafeRange(Offset position) {
    final isXValid =
        position.dx >= initialLength &&
        position.dx < (mapWidth - initialLength);
    final isYValid =
        position.dy >= initialLength &&
        position.dy < (mapHeight - initialLength);
    return isXValid && isYValid;
  }

  void addFood(Offset position) {
    if (getNearbyFoodPosition(position, Food.size * 4) == null &&
        isInSafeRange(position)) {
      foods.add(Food(position: position));
    }
  }

  Offset? getNearbyFoodPosition(Offset position, double threshold) {
    for (final food in foods) {
      final distance = (position - food.position).distance;
      if (distance < threshold) {
        return food.position;
      }
    }
    return null; // 无附近食物
  }

  void initTicker() {
    _ticker = Ticker(_gameLoop);
  }

  void resumeGame() {
    gameState.value = true;
    _ticker.start();
  }

  void suspendGame() {
    gameState.value = false;
    if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void toggleState() {
    if (gameState.value) {
      suspendGame();
    } else {
      resumeGame();
    }
  }

  void _gameLoop(Duration elapsed) {
    if (!gameState.value) return;

    // 计算当前帧与上一帧的时间间隔（单位：秒）
    final currentElapsed = elapsed.inMilliseconds / 1000.0;
    final deltaTime = currentElapsed - _lastElapsed;
    _lastElapsed = currentElapsed; // 更新上一帧时间

    final clampedDeltaTime = deltaTime.clamp(0.004, 0.02); // 限制到240hz到50hz之间

    _updateSnakes(clampedDeltaTime);
    _checkDangerousCollisions();
    _checkFoodCollisions();
    handleTickerCallback(deltaTime);
    notifyListeners();
  }

  void _updateSnakes(double deltaTime) {
    for (final entry in snakes.entries) {
      final id = entry.key;
      final snake = entry.value;

      // 先将旧的头部添加到身体中
      snake.body.insert(0, snake.head);

      _updateOtherSnakeCollision(id, snake.head);

      final moveDistance = snake.currentSpeed * deltaTime;

      // 根据新的头部坐标创建新的头部
      snake.head = Offset(
        snake.head.dx + cos(snake.angle) * moveDistance,
        snake.head.dy + sin(snake.angle) * moveDistance,
      );

      snake.currentLength += moveDistance;

      // 判断是否需要移除尾部
      while (snake.body.length > 2 && snake.currentLength > snake.length) {
        final last = snake.body.removeLast();
        _cleanupOtherSnakeCollision(last);
        final secondLast = snake.body.last;
        snake.currentLength -= (last - secondLast).distance;
      }
    }
  }

  // 遍历厂上每条蛇的身体，找到距离自己头部最近的点
  void _updateSelfSnakeCollision(int id, Snake snake) {
    for (final otherEntry in snakes.entries) {
      final otherId = otherEntry.key;
      final otherSnake = otherEntry.value;
      for (final bodyPart in otherSnake.body) {
        final distance = (snake.head - bodyPart).distance;

        if (!_snakeCollision.containsKey(id) ||
            _snakeCollision[id]!.distance > distance) {
          _snakeCollision[id] = NearestPoint(
            source: otherId,
            position: bodyPart,
            distance: distance,
          );
        }
      }
    }
  }

  // 遍历其他蛇最近的点，如果比之更新，替换之
  void _updateOtherSnakeCollision(int id, Offset position) {
    for (final entry in snakes.entries) {
      final otherId = entry.key;
      final otherSnake = entry.value;

      if (otherId == id) continue; // 跳过自己

      final distance = (position - otherSnake.head).distance;
      if (!_snakeCollision.containsKey(otherId) ||
          _snakeCollision[otherId]!.distance > distance) {
        _snakeCollision[otherId] = NearestPoint(
          source: id,
          position: position,
          distance: distance,
        );
      }
    }
  }

  // 遍历每条蛇最近的点，如果是该点，那么移除这个映射关系
  void _cleanupOtherSnakeCollision(Offset position) {
    final nearestToRemove = <int>[];
    for (final entry in _snakeCollision.entries) {
      if (entry.value.position == position) {
        nearestToRemove.add(entry.key);
      }
    }

    for (final id in nearestToRemove) {
      _snakeCollision.remove(id);
    }
  }

  void _checkDangerousCollisions() {
    final snakesToRemove = <int>[];

    for (final entry in snakes.entries) {
      final id = entry.key;
      final snake = entry.value;

      if (_checkWallCollision(snake.head)) {
        if (id == identity) {
          _handleGameOver(snake.length);
          return;
        } else {
          snakesToRemove.add(id);
          continue;
        }
      }

      // 使用snakeCollision进行快速碰撞检测
      final nearestPoint = _snakeCollision[id];
      if (nearestPoint != null) {
        final otherSnake = snakes[nearestPoint.source];
        if (otherSnake != null) {
          final collisionDistance =
              (snake.style.headSize + otherSnake.style.bodySize) / 2;

          if (nearestPoint.distance < collisionDistance) {
            if (id == identity) {
              _handleGameOver(snake.length);
              return;
            } else {
              snakesToRemove.add(id);
            }
          }
        }
      }
    }

    for (final id in snakesToRemove) {
      final removedSnake = snakes[id];
      if (removedSnake != null) {
        for (int i = 0; i < removedSnake.body.length; i + 5) {
          addFood(removedSnake.body[i]);
        }

        _cleanupSelfSnakeCollision(id);
      }
      snakes.remove(id);
      handleRemoveSnakeCallback(id);
    }
  }

  // 遍历每条蛇最近的点，如果该点属于自己，移除该映射关系，最后移除自身的映射
  void _cleanupSelfSnakeCollision(int id) {
    final nearestToRemove = <int>[];
    for (final entry in _snakeCollision.entries) {
      if (entry.value.source == id) {
        nearestToRemove.add(entry.key);
      }
    }

    for (final removeId in nearestToRemove) {
      _snakeCollision.remove(removeId);
    }

    if (_snakeCollision.containsKey(id)) {
      _snakeCollision.remove(id);
    }
  }

  static bool _checkWallCollision(Offset head) {
    return head.dx < 0 ||
        head.dx > mapWidth ||
        head.dy < 0 ||
        head.dy > mapHeight;
  }

  void handleRemoveSnakeCallback(int index);

  void _checkFoodCollisions() {
    for (final snake in snakes.values) {
      for (int i = foods.length - 1; i >= 0; i--) {
        if (_isFoodCollided(snake, foods[i])) {
          snake.updateLength(Food.growthPerFood);
          foods.removeAt(i);
          break;
        }
      }
    }
  }

  bool _isFoodCollided(Snake snake, Food food) {
    return (snake.head - food.position).distance <
        (Food.size + snake.style.headSize) / 2;
  }

  void handleTickerCallback(double deltaTime);

  void updatePlayerAngle(double newAngle);
  void updatePlayerSpeed(bool isFaster);

  void _handleGameOver(int length) {
    suspendGame();
    handleGameOverCallback();
    pageNavigator.value = (context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("游戏结束"),
          content: Text("最终长度: $length"),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ).then((_) => leavePage());
    };
  }

  void handleGameOverCallback();

  void leavePage() {
    _navigateBack();
  }

  void _navigateBack() {
    pageNavigator.value = (context) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
