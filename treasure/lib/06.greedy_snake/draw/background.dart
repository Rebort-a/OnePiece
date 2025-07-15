import 'dart:math';

import 'package:flutter/material.dart';

import '../base.dart';

class BackgroundPainter extends CustomPainter {
  final Offset viewOffset;

  BackgroundPainter({required this.viewOffset});

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

    // 计算视野在实际地图中的范围
    final viewLeft = viewOffset.dx;
    final viewTop = viewOffset.dy;
    final viewRight = viewOffset.dx + size.width;
    final viewBottom = viewOffset.dy + size.height;

    // 计算实际需要绘制的网格范围
    final startX = (viewLeft / gridSize).floor() * gridSize;
    final endX = (viewRight / gridSize).ceil() * gridSize;
    final startY = (viewTop / gridSize).floor() * gridSize;
    final endY = (viewBottom / gridSize).ceil() * gridSize;

    // 绘制垂直网格线（只在边界内）
    for (double x = startX; x <= endX; x += gridSize) {
      // 检查是否在边界内
      if (x >= 0 && x <= mapWidth) {
        // 计算线条在边界内的起始和结束点
        double yStart = max(0, viewOffset.dy);
        double yEnd = min(mapHeight, viewOffset.dy + size.height);

        final lineStart = Offset(x - viewOffset.dx, yStart - viewOffset.dy);
        final lineEnd = Offset(x - viewOffset.dx, yEnd - viewOffset.dy);

        canvas.drawLine(lineStart, lineEnd, gridPaint);
      }
    }

    // 绘制水平网格线（只在边界内）
    for (double y = startY; y <= endY; y += gridSize) {
      // 检查是否在边界内
      if (y >= 0 && y <= mapHeight) {
        // 计算线条在边界内的起始和结束点
        double xStart = max(0, viewOffset.dx);
        double xEnd = min(mapWidth, viewOffset.dx + size.width);

        final lineStart = Offset(xStart - viewOffset.dx, y - viewOffset.dy);
        final lineEnd = Offset(xEnd - viewOffset.dx, y - viewOffset.dy);

        canvas.drawLine(lineStart, lineEnd, gridPaint);
      }
    }
  }

  void _drawBounds(Canvas canvas, Size size) {
    final boundsPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 绘制边界矩形（根据视野偏移调整）
    canvas.drawRect(
      Rect.fromLTWH(-viewOffset.dx, -viewOffset.dy, mapWidth, mapHeight),
      boundsPaint,
    );
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.viewOffset != viewOffset;
  }
}
