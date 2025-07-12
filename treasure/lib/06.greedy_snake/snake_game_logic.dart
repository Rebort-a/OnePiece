import 'dart:math';
import 'package:flutter/material.dart';

enum Direction { up, down, left, right }

class SnakeGameLogic {
  late List<Offset> snake;
  late Offset food;
  late Direction direction;
  late Direction nextDirection;
  late Size mapSize;
  late Size visibleMapSize;
  late Offset viewportPosition;
  late int score;
  bool gameOver = false;
  bool paused = false;

  SnakeGameLogic({required this.mapSize, required this.visibleMapSize}) {
    resetGame();
  }

  void resetGame() {
    snake = [
      Offset(mapSize.width / 2, mapSize.height / 2),
      Offset(mapSize.width / 2 - 10, mapSize.height / 2),
      Offset(mapSize.width / 2 - 20, mapSize.height / 2),
    ];
    direction = Direction.right;
    nextDirection = Direction.right;
    generateFood();
    score = 0;
    gameOver = false;
    paused = false;
    updateViewportPosition();
  }

  void generateFood() {
    final random = Random();
    double x, y;
    bool validPosition;

    do {
      x = (random.nextDouble() * (mapSize.width - 10)).floorToDouble();
      y = (random.nextDouble() * (mapSize.height - 10)).floorToDouble();
      x = (x / 10).floor() * 10;
      y = (y / 10).floor() * 10;

      validPosition = true;
      for (var segment in snake) {
        if ((segment.dx - x).abs() < 10 && (segment.dy - y).abs() < 10) {
          validPosition = false;
          break;
        }
      }
    } while (!validPosition);

    food = Offset(x, y);
  }

  void update(double dt) {
    if (gameOver || paused) return;

    direction = nextDirection;

    final head = snake.first;
    Offset newHead;

    switch (direction) {
      case Direction.up:
        newHead = Offset(head.dx, head.dy - 10);
        break;
      case Direction.down:
        newHead = Offset(head.dx, head.dy + 10);
        break;
      case Direction.left:
        newHead = Offset(head.dx - 10, head.dy);
        break;
      case Direction.right:
        newHead = Offset(head.dx + 10, head.dy);
        break;
    }

    // 检查是否撞到边界
    if (newHead.dx < 0 ||
        newHead.dx >= mapSize.width ||
        newHead.dy < 0 ||
        newHead.dy >= mapSize.height) {
      gameOver = true;
      return;
    }

    // 检查是否撞到自己
    for (var segment in snake) {
      if ((segment.dx - newHead.dx).abs() < 5 &&
          (segment.dy - newHead.dy).abs() < 5) {
        gameOver = true;
        return;
      }
    }

    snake.insert(0, newHead);

    // 检查是否吃到食物
    if ((newHead.dx - food.dx).abs() < 10 &&
        (newHead.dy - food.dy).abs() < 10) {
      score += 10;
      generateFood();
    } else {
      snake.removeLast();
    }

    updateViewportPosition();
  }

  void updateViewportPosition() {
    double viewX = snake.first.dx - visibleMapSize.width / 2;
    double viewY = snake.first.dy - visibleMapSize.height / 2;

    // 确保视口不会超出实际地图边界
    viewX = max(0, min(viewX, mapSize.width - visibleMapSize.width));
    viewY = max(0, min(viewY, mapSize.height - visibleMapSize.height));

    viewportPosition = Offset(viewX, viewY);
  }

  void changeDirection(Direction newDirection) {
    // 防止180度转向
    if ((direction == Direction.up && newDirection == Direction.down) ||
        (direction == Direction.down && newDirection == Direction.up) ||
        (direction == Direction.left && newDirection == Direction.right) ||
        (direction == Direction.right && newDirection == Direction.left)) {
      return;
    }

    nextDirection = newDirection;
  }

  // 网络对战相关预留接口
  void connectToServer(String serverAddress) {
    // 实现连接服务器的逻辑
  }

  void sendGameState() {
    // 实现发送游戏状态的逻辑
  }

  void receiveGameState() {
    // 实现接收游戏状态的逻辑
  }

  // 多玩家相关预留接口
  void joinMultiplayerGame(String gameId) {
    // 实现加入多人游戏的逻辑
  }

  void sendPlayerAction() {
    // 实现发送玩家动作的逻辑
  }
}
