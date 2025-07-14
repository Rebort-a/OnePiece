import 'package:flutter/material.dart';
import '../game_controller.dart';

class GameBackground extends StatelessWidget {
  final GameController controller;

  const GameBackground({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        final viewOffset = controller.calculateViewOffset(viewSize);

        return Container(
          color: Colors.black87,
          child: CustomPaint(
            painter: _BackgroundPainter(
              controller: controller,
              viewOffset: viewOffset,
            ),
            size: viewSize,
          ),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final GameController controller;
  final Offset viewOffset;

  _BackgroundPainter({required this.controller, required this.viewOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制地图内部区域（深绿色背景）
    _drawColor(canvas, size);

    // 绘制网格背景
    _drawGrid(canvas, size);

    // 绘制边界
    _drawBounds(canvas, size);
  }

  void _drawColor(Canvas canvas, Size size) {
    final mapRect = Rect.fromLTWH(
      -viewOffset.dx,
      -viewOffset.dy,
      GameController.mapWidth,
      GameController.mapHeight,
    );
    canvas.drawRect(mapRect, Paint()..color = Colors.green[900]!);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // 计算可见网格范围
    final startX = (viewOffset.dx / gridSize).floor() * gridSize;
    final startY = (viewOffset.dy / gridSize).floor() * gridSize;
    final endX = viewOffset.dx + size.width;
    final endY = viewOffset.dy + size.height;

    // 绘制垂直线
    for (double x = startX; x < endX; x += gridSize) {
      canvas.drawLine(
        Offset(x - viewOffset.dx, 0),
        Offset(x - viewOffset.dx, size.height),
        gridPaint,
      );
    }

    // 绘制水平线
    for (double y = startY; y < endY; y += gridSize) {
      canvas.drawLine(
        Offset(0, y - viewOffset.dy),
        Offset(size.width, y - viewOffset.dy),
        gridPaint,
      );
    }
  }

  void _drawBounds(Canvas canvas, Size size) {
    final boundsPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 绘制边界矩形（根据视野偏移调整）
    canvas.drawRect(
      Rect.fromLTWH(
        -viewOffset.dx,
        -viewOffset.dy,
        GameController.mapWidth,
        GameController.mapHeight,
      ),
      boundsPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.controller.snakeHeadPosition !=
            controller.snakeHeadPosition ||
        oldDelegate.viewOffset != viewOffset;
  }
}
