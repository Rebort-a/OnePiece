// background.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../base.dart';

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
