import 'dart:math';
import 'package:flutter/material.dart';

import '../00.common/model/convert.dart';

const double mapWidth = 2000;
const double mapHeight = 2000;

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

  Map<String, dynamic> toJson() {
    return {
      'headSize': headSize,
      'headColor': ConvertUtils.colorToJson(headColor),
      'eyeColor': ConvertUtils.colorToJson(eyeColor),
      'bodySize': bodySize,
      'bodyColor': ConvertUtils.colorToJson(bodyColor),
    };
  }

  static SnakeStyle fromJson(Map<String, dynamic> json) {
    return SnakeStyle(
      headSize: json['headSize'],
      headColor: ConvertUtils.colorFromJson(json['headColor']),
      eyeColor: ConvertUtils.colorFromJson(json['eyeColor']),
      bodySize: json['bodySize'],
      bodyColor: ConvertUtils.colorFromJson(json['bodyColor']),
    );
  }
}

class Snake {
  static const double initialSpeed = 200;
  static const double fastSpeed = 400;

  List<Offset> body = [];
  double _currentSpeed = initialSpeed;
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

  Offset calculateViewOffset(Size viewSize) {
    return Offset(head.dx - viewSize.width / 2, head.dy - viewSize.height / 2);
  }

  void updatePosition(double deltaTime) {
    body.insert(0, head);
    final moveDistance = _currentSpeed * deltaTime;

    head = Offset(
      head.dx + cos(angle) * moveDistance,
      head.dy + sin(angle) * moveDistance,
    );

    _currentLength += moveDistance;

    while (body.length > 2 && _currentLength > length) {
      final last = body.removeLast();
      final secondLast = body.last;
      _currentLength -= (last - secondLast).distance;
    }
  }

  void updateAngle(double newAngle) => angle = newAngle;
  void updateSpeed(bool isFaster) =>
      _currentSpeed = isFaster ? fastSpeed : initialSpeed;
  void updateLength(int step) => length += step;

  Map<String, dynamic> toJson() {
    return {
      'head': ConvertUtils.offsetToJson(head),
      'length': length,
      'angle': angle,
      'style': style.toJson(),
      'isFaster': _currentSpeed == fastSpeed,
    };
  }

  static Snake fromJson(Map<String, dynamic> json) {
    return Snake(
      head: ConvertUtils.offsetFromJson(json['head']),
      length: json['length'],
      angle: json['angle'],
      style: SnakeStyle.fromJson(json['style']),
    ).._currentSpeed = json['isFaster'] as bool ? fastSpeed : initialSpeed;
  }
}

class Food {
  static const double size = 20;
  static const int growthPerFood = 10;

  Offset position;
  Food({required this.position});

  Map<String, dynamic> toJson() => {
    'position': ConvertUtils.offsetToJson(position),
  };

  static Food fromJson(Map<String, dynamic> json) =>
      Food(position: ConvertUtils.offsetFromJson(json['position']));
}
