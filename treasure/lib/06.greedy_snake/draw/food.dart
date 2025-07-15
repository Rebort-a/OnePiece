// food.dart
import 'package:flutter/material.dart';
import '../base.dart';

class FoodPainter extends CustomPainter {
  final Offset viewOffset;
  final List<Food> foods;

  FoodPainter({required this.viewOffset, required this.foods});

  @override
  void paint(Canvas canvas, Size size) {
    final foodPaint = Paint()
      ..color = Colors.red
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
