import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GameController {
  // 游戏参数
  static const double mapWidth = 2000;
  static const double mapHeight = 2000;
  static const double initialSnakeSpeed = 200;
  static const double fastSnakeSpeed = 350;
  static const double snakeInitialLength = 100;
  static const double snakeGrowthPerFood = 50;
  static const double foodSize = 20;
  static const double snakeHeadSize = 20;
  static const double snakeBodySize = 18;

  // 游戏状态
  int score = 0;
  bool isGameOver = false;
  bool isSpeeding = false;
  double currentSpeed = initialSnakeSpeed;
  double snakeLength = snakeInitialLength;

  // 蛇的属性
  double snakeAngle = 0; // 弧度
  Offset snakeHeadPosition = Offset(mapWidth / 2, mapHeight / 2);
  List<Offset> snakeBody = [];

  // 食物属性
  Offset? foodPosition;

  // 回调函数
  final VoidCallback onGameOver;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onStateUpdated;
  // 定时器相关
  Timer? _gameTimer;
  final Duration _gameTick = const Duration(milliseconds: 30);

  GameController({
    required this.onGameOver,
    required this.onScoreChanged,
    required this.onStateUpdated,
  });

  // 开始游戏
  void startGame() {
    _initializeGameState();
    _startGameLoop();
  }

  // 初始化游戏状态
  void _initializeGameState() {
    score = 0;
    isGameOver = false;
    isSpeeding = false;
    currentSpeed = initialSnakeSpeed;
    snakeLength = snakeInitialLength;
    snakeHeadPosition = Offset(mapWidth / 2, mapHeight / 2);
    snakeAngle = 0;
    snakeBody = [];
    _generateFood();
  }

  // 生成食物
  void _generateFood() {
    final random = Random();
    foodPosition = Offset(
      foodSize + random.nextDouble() * (mapWidth - 2 * foodSize),
      foodSize + random.nextDouble() * (mapHeight - 2 * foodSize),
    );
  }

  // 开始游戏循环
  void _startGameLoop() {
    _gameTimer = Timer.periodic(_gameTick, (timer) {
      if (isGameOver) {
        timer.cancel();
        return;
      }
      _updateGameState();
    });
  }

  // 更新游戏状态
  void _updateGameState() {
    // 计算移动距离
    double deltaTime = _gameTick.inMilliseconds / 1000.0;
    double moveDistance = currentSpeed * deltaTime;

    // 更新蛇头位置
    double dx = cos(snakeAngle) * moveDistance;
    double dy = sin(snakeAngle) * moveDistance;
    snakeHeadPosition = Offset(
      snakeHeadPosition.dx + dx,
      snakeHeadPosition.dy + dy,
    );

    // 检查边界碰撞
    if (_checkBoundaryCollision()) {
      _handleGameOver();
      return;
    }

    // 更新蛇身
    snakeBody.insert(0, snakeHeadPosition);
    while (snakeBody.length > 1 && _calculateSnakeLength() > snakeLength) {
      snakeBody.removeLast();
    }

    // 检查食物碰撞
    if (_checkFoodCollision()) {
      _handleFoodCollision();
    }

    onStateUpdated();
  }

  // 计算蛇的总长度
  double _calculateSnakeLength() {
    if (snakeBody.length < 2) return 0;
    double length = 0;
    for (int i = 0; i < snakeBody.length - 1; i++) {
      length += (snakeBody[i] - snakeBody[i + 1]).distance;
    }
    return length;
  }

  // 检查边界碰撞
  bool _checkBoundaryCollision() {
    return snakeHeadPosition.dx < 0 ||
        snakeHeadPosition.dx > mapWidth ||
        snakeHeadPosition.dy < 0 ||
        snakeHeadPosition.dy > mapHeight;
  }

  // 检查食物碰撞
  bool _checkFoodCollision() {
    if (foodPosition == null) return false;
    return (snakeHeadPosition - foodPosition!).distance <
        (snakeHeadSize + foodSize) / 2;
  }

  // 处理食物碰撞
  void _handleFoodCollision() {
    score++;
    snakeLength += snakeGrowthPerFood;
    onScoreChanged(score);
    _generateFood();
  }

  // 处理游戏结束
  void _handleGameOver() {
    isGameOver = true;
    onGameOver();
  }

  // 设置方向
  void setDirection(double angle) {
    // 防止180度急转弯
    double angleDifference = angle - snakeAngle;
    while (angleDifference > pi) {
      angleDifference -= 2 * pi;
    }
    while (angleDifference < -pi) {
      angleDifference += 2 * pi;
    }

    if (angleDifference.abs() < pi * 0.9) {
      snakeAngle = angle;
    }
  }

  // 设置速度
  void setSpeed(bool speeding) {
    isSpeeding = speeding;
    currentSpeed = speeding ? fastSnakeSpeed : initialSnakeSpeed;
  }

  // 重置游戏
  void resetGame() {
    _gameTimer?.cancel();
    startGame();
  }

  // 计算相对视野偏移
  Offset calculateViewOffset(Size viewSize) {
    double offsetX = snakeHeadPosition.dx - viewSize.width / 2;
    double offsetY = snakeHeadPosition.dy - viewSize.height / 2;

    // // 限制偏移，确保不会超出地图边界
    // offsetX = offsetX.clamp(0, mapWidth - viewSize.width);
    // offsetY = offsetY.clamp(0, mapHeight - viewSize.height);

    return Offset(offsetX, offsetY);
  }
}
