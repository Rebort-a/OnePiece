import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'snake_game_logic.dart';

class SnakeGameUI extends StatefulWidget {
  const SnakeGameUI({super.key});

  @override
  State<SnakeGameUI> createState() => _SnakeGameUIState();
}

class _SnakeGameUIState extends State<SnakeGameUI> {
  late SnakeGameLogic gameLogic;
  late Size actualMapSize;
  late Timer gameTimer;
  bool isPortrait = true;

  @override
  void initState() {
    super.initState();
    // 实际地图比可见地图大
    actualMapSize = const Size(800, 800);
    gameLogic = SnakeGameLogic(
      mapSize: actualMapSize,
      visibleMapSize: const Size(400, 400),
    );
    startGame();
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }

  void startGame() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          gameLogic.update(0.15);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    isPortrait = screenSize.width < screenSize.height;
    final gameSize = Size(
      isPortrait ? screenSize.width * 0.9 : screenSize.height * 0.6,
      isPortrait ? screenSize.width * 0.9 : screenSize.height * 0.6,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Greedy Snake'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                gameLogic.resetGame();
              });
            },
          ),
          IconButton(
            icon: gameLogic.paused
                ? const Icon(Icons.play_arrow)
                : const Icon(Icons.pause),
            onPressed: () {
              setState(() {
                gameLogic.paused = !gameLogic.paused;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 分数显示
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '分数: ${gameLogic.score}',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          ),
          // 游戏区域
          Expanded(
            child: Center(
              child: Container(
                width: gameSize.width,
                height: gameSize.height,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(
                      details.globalPosition,
                    );
                    final center = Offset(
                      box.size.width / 2,
                      box.size.height / 2,
                    );

                    if (localPosition.dx < center.dx &&
                        localPosition.dy < center.dy) {
                      gameLogic.changeDirection(Direction.up);
                    } else if (localPosition.dx > center.dx &&
                        localPosition.dy < center.dy) {
                      gameLogic.changeDirection(Direction.right);
                    } else if (localPosition.dx < center.dx &&
                        localPosition.dy > center.dy) {
                      gameLogic.changeDirection(Direction.left);
                    } else {
                      gameLogic.changeDirection(Direction.down);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: SnakeGamePainter(
                            snake: gameLogic.snake,
                            food: gameLogic.food,
                            viewportPosition: gameLogic.viewportPosition,
                            mapSize: actualMapSize,
                            visibleSize: gameSize,
                          ),
                          size: gameSize,
                        ),
                        // 地图边缘渐变遮罩
                        _buildMapEdgeOverlay(gameSize),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 控制按钮 (仅在竖屏显示)
          if (isPortrait)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 60),
                      ElevatedButton(
                        onPressed: () =>
                            gameLogic.changeDirection(Direction.up),
                        child: const Icon(Icons.arrow_upward),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            gameLogic.changeDirection(Direction.left),
                        child: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 40),
                      ElevatedButton(
                        onPressed: () =>
                            gameLogic.changeDirection(Direction.right),
                        child: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 60),
                      ElevatedButton(
                        onPressed: () =>
                            gameLogic.changeDirection(Direction.down),
                        child: const Icon(Icons.arrow_downward),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ],
              ),
            ),
          // 游戏结束提示
          if (gameLogic.gameOver)
            Container(
              color: Colors.black54,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: const Text(
                '游戏结束! 点击重置按钮重新开始',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapEdgeOverlay(Size gameSize) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.7),
            ],
            stops: [0.0, 0.6, 0.8, 0.9, 1.0],
            center: Alignment.center,
            radius: 0.7,
          ),
        ),
      ),
    );
  }
}

class SnakeGamePainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final Offset viewportPosition;
  final Size mapSize;
  final Size visibleSize;

  SnakeGamePainter({
    required this.snake,
    required this.food,
    required this.viewportPosition,
    required this.mapSize,
    required this.visibleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 计算缩放比例
    final scale = min(
      visibleSize.width / mapSize.width,
      visibleSize.height / mapSize.height,
    );

    // 计算可见区域的像素大小
    final visibleWidth = mapSize.width * scale;
    final visibleHeight = mapSize.height * scale;

    // 绘制外部区域（黑色背景）
    final outsidePaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), outsidePaint);

    // 应用视口变换 - 确保地图居中显示
    canvas.save();
    canvas.scale(scale);
    canvas.translate(
      size.width / 2 - viewportPosition.dx,
      size.height / 2 - viewportPosition.dy,
    );

    // 绘制地图内部区域（绿色背景）
    final insidePaint = Paint()..color = Colors.green[900]!;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, mapSize.width, mapSize.height),
      insidePaint,
    );

    // 绘制地图边框
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, mapSize.width, mapSize.height),
      borderPaint,
    );

    // 绘制网格（可选）
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double x = 0; x < mapSize.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, mapSize.height), gridPaint);
    }

    for (double y = 0; y < mapSize.height; y += 10) {
      canvas.drawLine(Offset(0, y), Offset(mapSize.width, y), gridPaint);
    }

    // 绘制食物
    final foodPaint = Paint()..color = Colors.red;
    canvas.drawOval(Rect.fromCircle(center: food, radius: 8), foodPaint);

    // 绘制蛇
    for (int i = 0; i < snake.length; i++) {
      final segment = snake[i];
      final segmentPaint = Paint();

      // 蛇头和身体使用不同颜色
      if (i == 0) {
        segmentPaint.color = Colors.green;
      } else {
        // 蛇身体颜色渐变
        final colorFactor = 1.0 - (i / snake.length * 0.7);
        segmentPaint.color = Colors.green.withValues(alpha: colorFactor);
      }

      // 绘制蛇的每一段
      final radius = i == 0 ? 8.0 : 6.0;
      canvas.drawOval(
        Rect.fromCircle(center: segment, radius: radius),
        segmentPaint,
      );

      // 蛇头添加眼睛
      if (i == 0) {
        final eyePaint = Paint()..color = Colors.white;
        final eyeSize = 2.0;

        // 根据蛇头方向确定眼睛位置
        switch (getSnakeDirection()) {
          case Direction.up:
            canvas.drawCircle(
              Offset(segment.dx - 4, segment.dy - 6),
              eyeSize,
              eyePaint,
            );
            canvas.drawCircle(
              Offset(segment.dx + 4, segment.dy - 6),
              eyeSize,
              eyePaint,
            );
            break;
          case Direction.down:
            canvas.drawCircle(
              Offset(segment.dx - 4, segment.dy + 6),
              eyeSize,
              eyePaint,
            );
            canvas.drawCircle(
              Offset(segment.dx + 4, segment.dy + 6),
              eyeSize,
              eyePaint,
            );
            break;
          case Direction.left:
            canvas.drawCircle(
              Offset(segment.dx - 6, segment.dy - 4),
              eyeSize,
              eyePaint,
            );
            canvas.drawCircle(
              Offset(segment.dx - 6, segment.dy + 4),
              eyeSize,
              eyePaint,
            );
            break;
          case Direction.right:
            canvas.drawCircle(
              Offset(segment.dx + 6, segment.dy - 4),
              eyeSize,
              eyePaint,
            );
            canvas.drawCircle(
              Offset(segment.dx + 6, segment.dy + 4),
              eyeSize,
              eyePaint,
            );
            break;
        }
      }
    }

    canvas.restore();
  }

  Direction getSnakeDirection() {
    if (snake.length < 2) return Direction.right;

    final head = snake[0];
    final neck = snake[1];

    if ((head.dx - neck.dx).abs() > (head.dy - neck.dy).abs()) {
      return head.dx > neck.dx ? Direction.right : Direction.left;
    } else {
      return head.dy > neck.dy ? Direction.down : Direction.up;
    }
  }

  @override
  bool shouldRepaint(covariant SnakeGamePainter oldDelegate) {
    return oldDelegate.snake != snake ||
        oldDelegate.food != food ||
        oldDelegate.viewportPosition != viewportPosition;
  }
}
