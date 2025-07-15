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

    // 绘制所有食物
    for (var food in foods) {
      // 食物位置（相对于视野）
      final foodPosition = food.position - viewOffset;

      // 绘制单个食物
      canvas.drawCircle(foodPosition, Food.foodSize, foodPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FoodPainter oldDelegate) {
    if (oldDelegate.viewOffset != viewOffset) return true;

    // 检查食物列表是否变化
    if (oldDelegate.foods.length != foods.length) return true;

    // 检查每个食物位置是否变化
    for (int i = 0; i < foods.length; i++) {
      if (oldDelegate.foods[i].position != foods[i].position) {
        return true;
      }
    }

    return false;
  }
}
