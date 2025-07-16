import 'dart:math';
import 'dart:ui';

import 'base.dart';
import 'foundation_manager.dart';

class LocalManager extends BaseManager {
  static const int generateCount = 5;
  static const int initialSnakeLength = 100;
  double _foodCheckAccumulator = 0.0;

  @override
  int get identity => 0;

  LocalManager() {
    initTicker();
    _initGame();
  }

  void _initGame() {
    snakes[identity] = createSnake(initialSnakeLength);
    for (int i = 1; i <= generateCount; i++) {
      snakes[identity + i] = createSnake(snakes[identity]!.length);
      foods.add(createFood());
    }
  }

  @override
  void handleTickerCallback(double deltaTime) {
    _handleFoodSearch(deltaTime);
  }

  void _handleFoodSearch(double deltaTime) {
    _foodCheckAccumulator += deltaTime;
    if (_foodCheckAccumulator > 0.5) {
      _adjustComputerAngle();
      _foodCheckAccumulator = 0;
    }
  }

  void _adjustComputerAngle() {
    for (final entry in snakes.entries) {
      if (entry.key != identity) {
        _turnToFood(entry.value);
      }
    }
  }

  void _turnToFood(Snake snake) {
    final nearest = _findNearestFood(snake.head);
    if (nearest != null) {
      final dx = nearest.position.dx - snake.head.dx;
      final dy = nearest.position.dy - snake.head.dy;
      snake.updateAngle(atan2(dy, dx));
    }
  }

  Food? _findNearestFood(Offset position) {
    if (foods.isEmpty) return null;

    Food? nearest;
    double? minDistance;

    for (final food in foods) {
      final distance = (position - food.position).distance;
      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
        nearest = food;
      }
    }
    return nearest;
  }

  @override
  void handleRemoveSnakeCallback(int index) {
    snakes[index] = createSnake(snakes[identity]!.length);
  }

  @override
  void handleRemoveFoodCallback(int index) {
    foods.add(createFood());
  }

  @override
  void updatePlayerAngle(double newAngle) {
    snakes[identity]!.updateAngle(newAngle);
  }

  @override
  void updatePlayerSpeed(bool isFaster) {
    snakes[identity]!.updateSpeed(isFaster);
  }
}
