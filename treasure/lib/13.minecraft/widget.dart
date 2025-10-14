import 'package:flutter/material.dart';

import '../00.common/component/bool_button.dart';

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

    // 绘制十字准星
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
  final Function(double, double) onMovement;
  final VoidCallback onStop;
  final VoidCallback onJump;

  const MobileControls({
    super.key,
    required this.onMovement,
    required this.onStop,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 左侧：虚拟摇杆（控制移动）
        Positioned(
          left: 20,
          bottom: 20,
          child: Joystick(onDirectionChanged: onMovement, onStop: onStop),
        ),

        // 右侧：跳跃按钮
        Positioned(
          right: 20,
          bottom: 20,
          child: BoolButton(
            icon: Icons.arrow_upward,
            onChanged: (isDown) {
              if (isDown) onJump();
            },
          ),
        ),
      ],
    );
  }
}

class Joystick extends StatefulWidget {
  final void Function(double horizontal, double vertical) onDirectionChanged;
  final VoidCallback onStop;

  const Joystick({
    super.key,
    required this.onDirectionChanged,
    required this.onStop,
  });

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
    widget.onDirectionChanged(0, 0);
    widget.onStop();
  }

  void _updateStickPosition(Offset localPosition) {
    final centerOffset = Offset(_baseRadius, _baseRadius);
    final relativePosition = localPosition - centerOffset;
    final distance = relativePosition.distance;

    // 限制摇杆在基座范围内
    final clampedDistance = distance > _baseRadius ? _baseRadius : distance;
    final normalized = clampedDistance > 0
        ? relativePosition / distance
        : Offset.zero;

    final clampedPosition = normalized * clampedDistance;

    // 计算归一化的方向向量
    final horizontal = normalized.dx;
    final vertical = -normalized.dy; // 反转Y轴，使向上为正

    widget.onDirectionChanged(horizontal, vertical);

    setState(() {
      _stickPosition = clampedPosition;
    });
  }
}
