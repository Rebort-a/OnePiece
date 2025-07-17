import 'dart:math';

import 'package:flutter/material.dart';

import 'base.dart';

class DrawRegion extends StatelessWidget {
  final int identity;
  final Color backgroundColor;
  final Map<int, Snake> snakes;
  final List<Food> foods;

  const DrawRegion({
    super.key,
    required this.identity,
    required this.backgroundColor,
    required this.snakes,
    required this.foods,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        final viewOffset =
            snakes[identity]?.calculateViewOffset(viewSize) ?? Offset.zero;

        return Stack(
          children: [
            Container(
              color: backgroundColor,
              child: CustomPaint(
                painter: BackgroundPainter(viewOffset: viewOffset),
                size: viewSize,
              ),
            ),
            CustomPaint(
              painter: SnakePainter(
                viewOffset: viewOffset,
                snakes: snakes.values.toList(),
              ),
              size: viewSize,
            ),
            CustomPaint(
              painter: FoodPainter(viewOffset: viewOffset, foods: foods),
              size: viewSize,
            ),
          ],
        );
      },
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Offset viewOffset;

  BackgroundPainter({required this.viewOffset});

  @override
  void paint(Canvas canvas, Size size) {
    _drawColor(canvas);
    _drawGrid(canvas, size);
    _drawBounds(canvas);
  }

  void _drawColor(Canvas canvas) {
    final mapRect = Rect.fromLTWH(
      -viewOffset.dx,
      -viewOffset.dy,
      mapWidth,
      mapHeight,
    );
    canvas.drawRect(mapRect, Paint()..color = Colors.green[900]!);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridSize = 50.0;
    final viewRect = Rect.fromLTRB(
      viewOffset.dx,
      viewOffset.dy,
      viewOffset.dx + size.width,
      viewOffset.dy + size.height,
    );

    // Vertical lines
    for (
      double x = _alignCoordinate(viewRect.left, gridSize);
      x <= viewRect.right;
      x += gridSize
    ) {
      if (x < 0 || x > mapWidth) continue;

      final lineStart = Offset(
        x - viewOffset.dx,
        max(0, viewOffset.dy) - viewOffset.dy,
      );
      final lineEnd = Offset(
        x - viewOffset.dx,
        min(mapHeight, viewOffset.dy + size.height) - viewOffset.dy,
      );
      canvas.drawLine(lineStart, lineEnd, gridPaint);
    }

    // Horizontal lines
    for (
      double y = _alignCoordinate(viewRect.top, gridSize);
      y <= viewRect.bottom;
      y += gridSize
    ) {
      if (y < 0 || y > mapHeight) continue;

      final lineStart = Offset(
        max(0, viewOffset.dx) - viewOffset.dx,
        y - viewOffset.dy,
      );
      final lineEnd = Offset(
        min(mapWidth, viewOffset.dx + size.width) - viewOffset.dx,
        y - viewOffset.dy,
      );
      canvas.drawLine(lineStart, lineEnd, gridPaint);
    }
  }

  double _alignCoordinate(double value, double grid) =>
      (value / grid).floor() * grid;

  void _drawBounds(Canvas canvas) {
    final boundsPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(
      Rect.fromLTWH(-viewOffset.dx, -viewOffset.dy, mapWidth, mapHeight),
      boundsPaint,
    );
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) =>
      oldDelegate.viewOffset != viewOffset;
}

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

class FoodPainter extends CustomPainter {
  final Offset viewOffset;
  final List<Food> foods;

  FoodPainter({required this.viewOffset, required this.foods});

  @override
  void paint(Canvas canvas, Size size) {
    final foodPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    for (final food in foods) {
      final position = food.position - viewOffset;
      canvas.drawCircle(position, Food.size, foodPaint);
    }
  }

  @override
  bool shouldRepaint(FoodPainter oldDelegate) {
    return oldDelegate.viewOffset != viewOffset ||
        !_listsEqual(oldDelegate.foods, foods);
  }

  bool _listsEqual(List<Food> a, List<Food> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].position != b[i].position) return true;
    }
    return false;
  }
}
