import 'package:flutter/material.dart';

import '../base.dart';
import 'background.dart';
import 'food.dart';
import 'snack.dart';

class DrawRegion extends StatelessWidget {
  final Color backgroundColor;
  final int identity;
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
      builder: (BuildContext context, BoxConstraints constraints) {
        final viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        Offset viewOffset = Offset.zero;

        if (snakes.containsKey(identity)) {
          viewOffset = snakes[identity]!.calculateViewOffset(viewSize);
        }

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
