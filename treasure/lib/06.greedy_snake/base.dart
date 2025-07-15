import 'dart:math';

import 'package:flutter/material.dart';

const double mapWidth = 2000;
const double mapHeight = 2000;

const double iniSnakeSpeed = 100;
const double fastSnakeSpeed = 180;

const double foodSize = 20;
const double snakeGrowthPerFood = 15;

class SnakeStyle {
  final double headSize;
  final Color headColor;
  final Color eyeColor;

  final double bodySize;
  final Color bodyColor;

  const SnakeStyle({
    required this.headSize,
    required this.headColor,
    required this.eyeColor,

    required this.bodySize,
    required this.bodyColor,
  });

  // 默认样式
  static const defaultStyle = SnakeStyle(
    headSize: 10.0,
    headColor: Colors.green,
    eyeColor: Colors.white,

    bodySize: 12.0,
    bodyColor: Colors.green,
  );

  // 生成随机样式
  static SnakeStyle random() {
    final random = Random();
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.yellow,
      Colors.orange,
      Colors.pink,
    ];
    final color = colors[random.nextInt(colors.length)];

    return SnakeStyle(
      headSize: 8 + random.nextDouble() * 4.0,
      headColor: color.shade800,
      eyeColor: Colors.white,

      bodySize: 10 + random.nextDouble() * 8.0,
      bodyColor: color,
    );
  }

  // 复制并修改部分属性
  SnakeStyle copyWith({
    double? headSize,
    Color? headColor,
    Color? eyeColor,

    double? bodySize,
    Color? bodyColor,
  }) {
    return SnakeStyle(
      headSize: headSize ?? this.headSize,
      headColor: headColor ?? this.headColor,
      eyeColor: eyeColor ?? this.eyeColor,

      bodySize: bodySize ?? this.bodySize,
      bodyColor: bodyColor ?? this.bodyColor,
    );
  }
}

class Snake {
  List<Offset> body = [];
  double currentSpeed = iniSnakeSpeed;
  double _currentLength = 0.0;

  Offset head;
  int length;
  double angle;
  SnakeStyle style;

  Snake({
    required this.head,
    required this.length,
    required this.angle,
    required this.style,
  });

  // 计算相对视野偏移
  Offset calculateViewOffset(Size viewSize) {
    double offsetX = head.dx - viewSize.width / 2;
    double offsetY = head.dy - viewSize.height / 2;

    return Offset(offsetX, offsetY);
  }

  // 更新蛇的位置
  void updatePosition(double deltaTime) {
    // 将之前的蛇头加入蛇身
    body.insert(0, head);

    // 计算移动距离
    double moveDistance = currentSpeed * deltaTime;

    // 更新蛇头位置
    double dx = cos(angle) * moveDistance;
    double dy = sin(angle) * moveDistance;
    head = Offset(head.dx + dx, head.dy + dy);

    // 蛇身长度增加
    _currentLength += moveDistance;

    // 蛇身长度大于最大长度时，删除最后一节
    while (body.length > 2 && _currentLength > length) {
      Offset last = body.removeLast();
      Offset secondLast = body.last;
      _currentLength -= (last - secondLast).distance;
    }
  }

  void updateAngle(double newAngle) {
    angle = newAngle;
  }

  void updateSpeed(bool isFaster) {
    currentSpeed = isFaster ? fastSnakeSpeed : iniSnakeSpeed;
  }

  void updateLength(int step) {
    length += step;
  }
}

class Food {
  Offset position;
  Food({required this.position});
}
