// snake.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../base.dart';

class SnakePainter extends CustomPainter {
  final Offset viewOffset;
  final List<Snake> snakes;

  SnakePainter({required this.viewOffset, required this.snakes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final snake in snakes) {
      _drawSnake(canvas, snake);
    }
  }

  void _drawSnake(Canvas canvas, Snake snake) {
    _drawSnakeBody(canvas, snake);
    _drawSnakeHead(canvas, snake);
  }

  void _drawSnakeBody(Canvas canvas, Snake snake) {
    final bodyPaint = Paint()
      ..color = snake.style.bodyColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < snake.body.length - 1; i++) {
      final p1 = snake.body[i] - viewOffset;
      final p2 = snake.body[i + 1] - viewOffset;
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final distance = sqrt(dx * dx + dy * dy);
      final angle = atan2(dy, dx);

      // 创建变换矩阵
      final matrix = Matrix4.identity()
        ..translate(p1.dx, p1.dy)
        ..rotateZ(angle);

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

    final headPosition = snake.head - viewOffset;
    canvas.drawCircle(headPosition, snake.style.headSize, headPaint);

    final eyeDistance = snake.style.headSize * 0.6;
    final eyeSize = snake.style.headSize * 0.3;

    final eye1Position = Offset(
      headPosition.dx + cos(snake.angle - pi / 4) * eyeDistance,
      headPosition.dy + sin(snake.angle - pi / 4) * eyeDistance,
    );

    final eye2Position = Offset(
      headPosition.dx + cos(snake.angle + pi / 4) * eyeDistance,
      headPosition.dy + sin(snake.angle + pi / 4) * eyeDistance,
    );

    canvas.drawCircle(eye1Position, eyeSize, eyePaint);
    canvas.drawCircle(eye2Position, eyeSize, eyePaint);
  }

  @override
  bool shouldRepaint(SnakePainter oldDelegate) {
    return oldDelegate.viewOffset != viewOffset ||
        !_snakesEqual(oldDelegate.snakes, snakes);
  }

  bool _snakesEqual(List<Snake> a, List<Snake> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      final oldSnake = a[i];
      final newSnake = b[i];
      if (oldSnake.body != newSnake.body ||
          oldSnake.head != newSnake.head ||
          oldSnake.angle != newSnake.angle ||
          oldSnake.style != newSnake.style) {
        return false;
      }
    }
    return true;
  }
}
