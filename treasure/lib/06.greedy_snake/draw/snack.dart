import 'dart:math';

import 'package:flutter/material.dart';
import '../base.dart';

class SnakePainter extends CustomPainter {
  final Offset viewOffset;
  final List<Snake> snakes;

  SnakePainter({required this.viewOffset, required this.snakes});

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制所有蛇
    for (var snake in snakes) {
      _drawSnake(canvas, snake);
    }
  }

  void _drawSnake(Canvas canvas, Snake snake) {
    // 绘制蛇身
    _drawSnakeBody(canvas, snake);

    // 绘制蛇头
    _drawSnakeHead(canvas, snake);
  }

  void _drawSnakeBody(Canvas canvas, Snake snake) {
    final bodyPaint = Paint()
      ..color = snake.style.bodyColor
      ..style = PaintingStyle.fill;

    // 绘制蛇身各段
    for (int i = 0; i < snake.body.length - 1; i++) {
      final p1 = snake.body[i] - viewOffset;
      final p2 = snake.body[i + 1] - viewOffset;

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
            -snake.style.bodySize / 2,
            distance,
            snake.style.bodySize,
          ),
          Radius.circular(snake.style.bodySize / 2),
        ),
        bodyPaint,
      );
      canvas.restore();
    }
  }

  void _drawSnakeHead(Canvas canvas, Snake snake) {
    final headPaint = Paint()
      ..color = snake.style.headColor
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()
      ..color = snake.style.eyeColor
      ..style = PaintingStyle.fill;

    // 蛇头位置（相对于视野）
    final headPosition = snake.head - viewOffset;

    // 绘制蛇头圆形
    canvas.drawCircle(headPosition, snake.style.headSize, headPaint);

    // 绘制眼睛
    final eyeDistance = snake.style.headSize * 0.6;
    final eyeSize = snake.style.headSize * 0.3;

    // 计算眼睛位置（基于蛇头朝向）
    final eye1Angle = snake.angle - pi / 4;
    final eye2Angle = snake.angle + pi / 4;

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
  bool shouldRepaint(covariant SnakePainter oldDelegate) {
    if (oldDelegate.viewOffset != viewOffset) return true;

    if (oldDelegate.snakes.length != snakes.length) return true;

    for (int i = 0; i < snakes.length; i++) {
      final oldSnake = oldDelegate.snakes[i];
      final newSnake = snakes[i];

      if (oldSnake.body != newSnake.body ||
          oldSnake.head != newSnake.head ||
          oldSnake.angle != newSnake.angle ||
          oldSnake.style != newSnake.style) {
        return true;
      }
    }

    return false;
  }
}
