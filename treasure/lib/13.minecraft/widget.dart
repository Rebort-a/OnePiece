import 'package:flutter/material.dart';

import 'base.dart';

// 十字准星组件
class Crosshair extends StatelessWidget {
  const Crosshair({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(painter: CrosshairPainter()),
      ),
    );
  }
}

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final third = size.width / 3;

    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, center.dy - third),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + third),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(center.dx - third, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + third, center.dy),
      Offset(size.width, center.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MobileControls extends StatelessWidget {
  final Function(Vector2) onDrag;
  final VoidCallback onJump;

  const MobileControls({super.key, required this.onDrag, required this.onJump});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(left: 20, bottom: 20, child: Joystick(onDrag: onDrag)),
        Positioned(
          right: 20,
          bottom: 20,
          child: BoolButton(icon: Icons.arrow_upward, onPressed: onJump),
        ),
      ],
    );
  }
}

class Joystick extends StatefulWidget {
  final void Function(Vector2) onDrag;

  const Joystick({super.key, required this.onDrag});

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  static const double _baseRadius = 60;
  static const double _stickRadius = 30;

  Offset _stickPosition = Offset.zero;

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
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Transform.translate(
            offset: _stickPosition,
            child: Container(
              width: _stickRadius * 2,
              height: _stickRadius * 2,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),
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

  void _onDragEnd(DragEndDetails _) {
    setState(() {
      _stickPosition = Offset.zero;
    });
    widget.onDrag(Vector2.zero);
  }

  void _updateStickPosition(Offset localPosition) {
    final centerOffset = Offset(_baseRadius, _baseRadius);
    final relativePosition = localPosition - centerOffset;
    final distance = relativePosition.distance;

    // 计算归一化向量
    final normalized = distance > 0 ? relativePosition / distance : Offset.zero;

    // 限制在单位圆内，并计算实际位置
    final double clampedDistance = distance.clamp(0, _baseRadius);
    final clampedPosition = normalized * clampedDistance;

    // 转换为 Vector2，范围 [-1, 1]
    widget.onDrag(Vector2(normalized.dx, -normalized.dy));

    setState(() {
      _stickPosition = clampedPosition;
    });
  }
}

class BoolButton extends StatefulWidget {
  final void Function() onPressed;
  final IconData icon;

  const BoolButton({super.key, required this.onPressed, required this.icon});

  @override
  State<BoolButton> createState() => _SpeedButtonState();
}

class _SpeedButtonState extends State<BoolButton> {
  bool _isPressed = false;
  static const double _buttonRadius = 60;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setState(true),
      onTapUp: (_) => _setState(false),
      onTapCancel: () => _setState(false),
      child: Container(
        width: _buttonRadius * 2,
        height: _buttonRadius * 2,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.black.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        child: Center(child: Icon(widget.icon, color: Colors.white, size: 30)),
      ),
    );
  }

  void _setState(bool isPressed) {
    if (isPressed) {
      widget.onPressed();
    }
    setState(() {
      _isPressed = isPressed;
    });
  }
}
