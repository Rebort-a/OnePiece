import 'dart:math';

import 'package:flutter/material.dart';

class Joystick extends StatefulWidget {
  final Function(double angle) onDirectionChanged;

  const Joystick({super.key, required this.onDirectionChanged});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _stickPosition = Offset.zero;
  static const double _baseRadius = 80;
  static const double _stickRadius = 40;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: Container(
        width: _baseRadius * 2,
        height: _baseRadius * 2,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(_baseRadius),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: _stickRadius * 2,
                height: _stickRadius * 2,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(_stickRadius),
                ),
                transform: Matrix4.translationValues(
                  _stickPosition.dx,
                  _stickPosition.dy,
                  0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    _updateStickPosition(details.localPosition);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _updateStickPosition(details.localPosition);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _stickPosition = Offset.zero;
      widget.onDirectionChanged(0);
    });
  }

  void _updateStickPosition(Offset localPosition) {
    // 计算相对中心的位置
    Offset relativePosition = localPosition - Offset(_baseRadius, _baseRadius);

    // 计算距离和角度
    double distance = relativePosition.distance;
    double angle = atan2(relativePosition.dy, relativePosition.dx);

    // 限制在圆内
    if (distance > _baseRadius) {
      relativePosition = Offset(
        cos(angle) * _baseRadius,
        sin(angle) * _baseRadius,
      );
    }

    setState(() {
      _stickPosition = relativePosition;
      widget.onDirectionChanged(angle);
    });
  }
}
