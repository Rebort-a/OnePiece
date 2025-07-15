// base.dart
import 'dart:math';
import 'package:flutter/material.dart';

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

  static const defaultStyle = SnakeStyle(
    headSize: 10.0,
    headColor: Colors.green,
    eyeColor: Colors.white,
    bodySize: 12.0,
    bodyColor: Colors.green,
  );

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
      'headColor': _colorToJson(headColor),
      'eyeColor': _colorToJson(eyeColor),
      'bodySize': bodySize,
      'bodyColor': _colorToJson(bodyColor),
    };
  }

  static SnakeStyle fromJson(Map<String, dynamic> json) {
    return SnakeStyle(
      headSize: json['headSize'],
      headColor: _colorFromJson(json['headColor']),
      eyeColor: _colorFromJson(json['eyeColor']),
      bodySize: json['bodySize'],
      bodyColor: _colorFromJson(json['bodyColor']),
    );
  }

  static Map<String, int> _colorToJson(Color color) => {
    'value': color.toARGB32(),
  };
  static Color _colorFromJson(Map<String, dynamic> json) =>
      Color(json['value']);
}

class Snake {
  static const double initialSpeed = 40;
  static const double fastSpeed = 70;

  List<Offset> body = [];
  double currentSpeed = initialSpeed;
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
    final moveDistance = currentSpeed * deltaTime;

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
      currentSpeed = isFaster ? fastSpeed : initialSpeed;
  void updateLength(int step) => length += step;

  Map<String, dynamic> toJson() {
    return {
      'head': _offsetToJson(head),
      'length': length,
      'angle': angle,
      'style': style.toJson(),
      'body': body.map(_offsetToJson).toList(),
      'currentSpeed': currentSpeed,
      '_currentLength': _currentLength,
    };
  }

  static Snake fromJson(Map<String, dynamic> json) {
    return Snake(
      head: _offsetFromJson(json['head']),
      length: json['length'],
      angle: json['angle'],
      style: SnakeStyle.fromJson(json['style']),
    );
  }

  static Map<String, double> _offsetToJson(Offset offset) => {
    'dx': offset.dx,
    'dy': offset.dy,
  };

  static Offset _offsetFromJson(Map<String, dynamic> json) =>
      Offset(json['dx'], json['dy']);
}

class Food {
  static const double size = 20;
  static const int growthPerFood = 15;

  Offset position;
  Food({required this.position});

  Map<String, dynamic> toJson() => {'position': Snake._offsetToJson(position)};

  static Food fromJson(Map<String, dynamic> json) =>
      Food(position: Snake._offsetFromJson(json['position']));
}
