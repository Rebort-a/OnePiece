import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../00.common/model/notifier.dart';
import 'base.dart';

abstract class BaseManager extends ChangeNotifier {
  final Random _random = Random();

  final Map<int, Snake> snakes = {};
  final List<Food> foods = [];

  late final Ticker _ticker;
  double _lastElapsed = 0;

  final pageNavigator = AlwaysNotifier<void Function(BuildContext)>((_) {});
  final gameState = ValueNotifier<bool>(false);

  int get identity;

  Snake createSnake(int length) => Snake(
    head: _randomPosition,
    length: _random.nextInt(length) + 30,
    angle: _random.nextDouble() * 2 * pi,
    style: SnakeStyle.random(),
  );

  Offset get _randomPosition => Offset(
    _random.nextDouble() * (mapWidth - 200) + 100,
    _random.nextDouble() * (mapHeight - 200) + 100,
  );

  Food createFood() => Food(position: _randomPosition);

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
    for (final snake in snakes.values) {
      snake.updatePosition(deltaTime);
    }
  }

  void _checkDangerousCollisions() {
    final snakesToRemove = <int>[];

    for (final entry in snakes.entries) {
      final id = entry.key;
      final snake = entry.value;

      if (checkWallCollision(snake.head)) {
        if (id == identity) {
          _handleGameOver();
          return;
        } else {
          snakesToRemove.add(id);
          continue;
        }
      }

      for (final otherEntry in snakes.entries) {
        final otherSnake = otherEntry.value;

        if (checkSnakeCollision(snake, otherSnake)) {
          if (id == identity) {
            _handleGameOver();
            return;
          } else {
            snakesToRemove.add(id);
            break;
          }
        }
      }
    }

    for (final id in snakesToRemove) {
      snakes.remove(id);
      handleRemoveSnakeCallback(id);
    }
  }

  static bool checkWallCollision(Offset head) {
    return head.dx < 0 ||
        head.dx > mapWidth ||
        head.dy < 0 ||
        head.dy > mapHeight;
  }

  static bool checkSnakeCollision(Snake snake, Snake other) {
    if (snake == other) return false;

    for (final bodyPart in other.body) {
      final distance = (snake.head - bodyPart).distance;
      if (distance < (snake.style.headSize + other.style.bodySize) / 2) {
        return true;
      }
    }
    return false;
  }

  void handleRemoveSnakeCallback(int index);

  void _checkFoodCollisions() {
    for (final snake in snakes.values) {
      for (int i = foods.length - 1; i >= 0; i--) {
        if (_isFoodCollided(snake, foods[i])) {
          snake.updateLength(Food.growthPerFood);
          foods.removeAt(i);
          handleRemoveFoodCallback(i);
          break;
        }
      }
    }
  }

  void handleRemoveFoodCallback(int index);

  bool _isFoodCollided(Snake snake, Food food) {
    return (snake.head - food.position).distance <
        (Food.size + snake.style.headSize) / 2;
  }

  void handleTickerCallback(double deltaTime);

  void updatePlayerAngle(double newAngle);
  void updatePlayerSpeed(bool isFaster);

  void _handleGameOver() {
    suspendGame();
    pageNavigator.value = (context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("游戏结束"),
          content: Text("最终长度: ${snakes[identity]?.length}"),
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
