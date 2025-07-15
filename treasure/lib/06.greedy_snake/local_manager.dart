// local_manager.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../00.common/model/notifier.dart';
import 'base.dart';

class LocalManager extends ChangeNotifier {
  static const int generateCount = 5;
  final _random = Random();

  final pageNavigator = AlwaysNotifier<void Function(BuildContext)>((_) {});
  final snakes = <int, Snake>{};
  final foods = <Food>[];
  int identity = 0;

  late final Ticker _ticker;
  bool paused = false;
  double _foodCheckAccumulator = 0;

  LocalManager() {
    _initGame();
    _startGameLoop();
  }

  void _initGame() {
    snakes[identity] = _createSnake();
    for (int i = 1; i <= generateCount; i++) {
      snakes[identity + i] = _createSnake();
      foods.add(Food(position: _randomPosition));
    }
  }

  Snake _createSnake() => Snake(
    head: _randomPosition,
    length: _randomLength,
    angle: _randomAngle,
    style: SnakeStyle.random(),
  );

  Offset get _randomPosition => Offset(
    _random.nextDouble() * (mapWidth - 200) + 100,
    _random.nextDouble() * (mapHeight - 200) + 100,
  );

  int get _randomLength => snakes.isNotEmpty
      ? _random.nextInt(snakes[identity]!.length) + 30
      : _random.nextInt(70) + 30;

  double get _randomAngle => _random.nextDouble() * 2 * pi;

  void _startGameLoop() {
    _ticker = Ticker(_gameLoop);
    _ticker.start();
  }

  void _gameLoop(Duration elapsed) {
    final deltaTime = min(elapsed.inMilliseconds / 1000.0, 0.1);

    for (var snake in snakes.values) {
      snake.updatePosition(deltaTime);
    }
    _handleCollisions();

    _foodCheckAccumulator += deltaTime;
    if (_foodCheckAccumulator > 0.5) {
      snakes.forEach((id, snake) {
        if (id != identity) _turnToFood(snake);
      });
      _foodCheckAccumulator = 0;
    }

    notifyListeners();
  }

  void _turnToFood(Snake snake) {
    final nearest = _nearestFood(snake.head);
    if (nearest != null) {
      final dx = nearest.position.dx - snake.head.dx;
      final dy = nearest.position.dy - snake.head.dy;
      snake.updateAngle(atan2(dy, dx));
    }
  }

  Food? _nearestFood(Offset position) {
    if (foods.isEmpty) return null;
    return foods.reduce(
      (a, b) =>
          (position - a.position).distance < (position - b.position).distance
          ? a
          : b,
    );
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
        if (id == identity) {
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
          foods.add(Food(position: _randomPosition));
          break;
        }
      }

      // Snake collision
      for (final other in snakes.entries) {
        if (id == other.key) continue;

        for (final bodyPart in other.value.body) {
          if ((snake.head - bodyPart).distance <
              snake.style.headSize / 2 + snake.style.headSize / 2) {
            if (id == identity) {
              _handleGameOver();
            } else {
              toRemove.add(id);
            }
            break;
          }
        }
      }
    }

    for (var id in toRemove) {
      snakes.remove(id);
      snakes[id] = _createSnake();
    }
  }

  void _handleGameOver() {
    _ticker.stop();
    pageNavigator.value = (context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("游戏结束"),
          content: Text("最终长度: ${snakes[0]?.length}"),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateBack();
              },
            ),
          ],
        ),
      );
    };
  }

  void _navigateBack() =>
      pageNavigator.value = (context) => Navigator.of(context).pop();

  void updatePlayerAngle(double newAngle) =>
      snakes[identity]?.updateAngle(newAngle);
  void updatePlayerSpeed(bool isFaster) =>
      snakes[identity]?.updateSpeed(isFaster);
  void pause() => _ticker.stop();
  void resume() => _ticker.start();
  void leavePage() => _navigateBack();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
