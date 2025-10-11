import 'package:flutter/material.dart';

class BoolButton extends StatefulWidget {
  final Function(bool isDown) onChanged;
  final IconData icon;

  const BoolButton({super.key, required this.onChanged, required this.icon});

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

  void _setState(bool isDown) {
    widget.onChanged(isDown);
    setState(() {
      _isPressed = isDown;
    });
  }
}
