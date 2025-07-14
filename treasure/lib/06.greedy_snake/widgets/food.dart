import 'package:flutter/material.dart';
import '../game_controller.dart';

class Food extends StatelessWidget {
  final GameController controller;

  const Food({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        final viewOffset = controller.calculateViewOffset(viewSize);

        return CustomPaint(
          painter: _FoodPainter(controller: controller, viewOffset: viewOffset),
          size: viewSize,
        );
      },
    );
  }
}

class _FoodPainter extends CustomPainter {
  final GameController controller;
  final Offset viewOffset;

  _FoodPainter({required this.controller, required this.viewOffset});

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.foodPosition == null) return;

    final foodPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // 食物位置（相对于视野）
    final foodPosition = controller.foodPosition! - viewOffset;

    // 绘制食物
    canvas.drawCircle(foodPosition, GameController.foodSize, foodPaint);
  }

  @override
  bool shouldRepaint(covariant _FoodPainter oldDelegate) {
    return oldDelegate.controller.foodPosition != controller.foodPosition ||
        oldDelegate.viewOffset != viewOffset;
  }
}
