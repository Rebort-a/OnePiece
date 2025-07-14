import 'dart:math';
import 'package:flutter/material.dart';
import '../game_controller.dart';

class Snake extends StatelessWidget {
  final GameController controller;

  const Snake({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        final viewOffset = controller.calculateViewOffset(viewSize);

        return CustomPaint(
          painter: _SnakePainter(
            controller: controller,
            viewOffset: viewOffset,
          ),
          size: viewSize,
        );
      },
    );
  }
}

class _SnakePainter extends CustomPainter {
  final GameController controller;
  final Offset viewOffset;

  _SnakePainter({required this.controller, required this.viewOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制蛇身
    _drawSnakeBody(canvas);

    // 绘制蛇头
    _drawSnakeHead(canvas);
  }

  void _drawSnakeBody(Canvas canvas) {
    final bodyPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    // 绘制蛇身各段
    for (int i = 0; i < controller.snakeBody.length - 1; i++) {
      final p1 = controller.snakeBody[i] - viewOffset;
      final p2 = controller.snakeBody[i + 1] - viewOffset;

      // 计算两点之间的距离和角度
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final distance = sqrt(dx * dx + dy * dy);
      final angle = atan2(dy, dx);

      // 创建变换矩阵
      final matrix = Matrix4.identity()
        ..translate(p1.dx, p1.dy)
        ..rotateZ(angle);

      // 绘制矩形（蛇身段）
      canvas.save();
      canvas.transform(matrix.storage);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            0,
            -GameController.snakeBodySize / 2,
            distance,
            GameController.snakeBodySize,
          ),
          Radius.circular(GameController.snakeBodySize / 2),
        ),
        bodyPaint,
      );
      canvas.restore();
    }
  }

  void _drawSnakeHead(Canvas canvas) {
    final headPaint = Paint()
      ..color = Colors.green.shade800
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 蛇头位置（相对于视野）
    final headPosition = controller.snakeHeadPosition - viewOffset;

    // 绘制蛇头圆形
    canvas.drawCircle(headPosition, GameController.snakeHeadSize, headPaint);

    // 绘制眼睛
    final eyeDistance = GameController.snakeHeadSize * 0.6;
    final eyeSize = GameController.snakeHeadSize * 0.3;

    // 计算眼睛位置（基于蛇头朝向）
    final eye1Angle = controller.snakeAngle - pi / 4;
    final eye2Angle = controller.snakeAngle + pi / 4;

    final eye1Position = Offset(
      headPosition.dx + cos(eye1Angle) * eyeDistance,
      headPosition.dy + sin(eye1Angle) * eyeDistance,
    );

    final eye2Position = Offset(
      headPosition.dx + cos(eye2Angle) * eyeDistance,
      headPosition.dy + sin(eye2Angle) * eyeDistance,
    );

    // 绘制眼睛
    canvas.drawCircle(eye1Position, eyeSize, eyePaint);
    canvas.drawCircle(eye2Position, eyeSize, eyePaint);
  }

  @override
  bool shouldRepaint(covariant _SnakePainter oldDelegate) {
    return oldDelegate.controller.snakeBody != controller.snakeBody ||
        oldDelegate.controller.snakeHeadPosition !=
            controller.snakeHeadPosition ||
        oldDelegate.controller.snakeAngle != controller.snakeAngle ||
        oldDelegate.viewOffset != viewOffset;
  }
}
