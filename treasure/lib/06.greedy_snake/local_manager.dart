import 'dart:math';

import 'base.dart';
import 'foundation_manager.dart';

class LocalManager extends FoundationalManager {
  static const int generateCount = 5;
  double _foodCheckAccumulator = 0.0;

  @override
  int get identity => 0;

  LocalManager() {
    initTicker();
    _initGame();
  }

  void _initGame() {
    snakes[identity] = createSnake(FoundationalManager.initialLength);
    for (int i = 1; i <= generateCount; i++) {
      snakes[identity + i] = createSnake(snakes[identity]!.length);
      createFood(randomPosition);
    }
  }

  @override
  void handleTickerCallback(double deltaTime) {
    _handleFoodSearch(deltaTime);
  }

  void _handleFoodSearch(double deltaTime) {
    _foodCheckAccumulator += deltaTime;
    if (_foodCheckAccumulator > 0.3) {
      _adjustAllComputersAngle();
      _foodCheckAccumulator = 0;
    }
  }

  void _adjustAllComputersAngle() {
    for (final entry in snakes.entries) {
      if (entry.key != identity) {
        _turnToHappiness(entry.value);
      }
    }
  }

  void _turnToHappiness(Snake snake) {
    final nearest = getNearbyFoodPosition(
      snake.head,
      FoundationalManager.initialLength * 4,
    );
    if (nearest != null) {
      final dx = nearest.dx - snake.head.dx;
      final dy = nearest.dy - snake.head.dy;
      snake.updateAngle(atan2(dy, dx));
    } else if (!isPositionInSafeRange(snake.head)) {
      final dx = mapWidth / 2 - snake.head.dx;
      final dy = mapHeight / 2 - snake.head.dy;
      snake.updateAngle(atan2(dy, dx));
    }
  }

  @override
  void handleRemoveSnakeCallback(int index) {
    snakes[index] = createSnake(snakes[identity]!.length);
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
