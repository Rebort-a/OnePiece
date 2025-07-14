import 'package:flutter/material.dart';

class SpeedButton extends StatefulWidget {
  final Function(bool isSpeeding) onSpeedChanged;

  const SpeedButton({super.key, required this.onSpeedChanged});

  @override
  State<SpeedButton> createState() => _SpeedButtonState();
}

class _SpeedButtonState extends State<SpeedButton> {
  bool _isPressed = false;
  static const double _buttonRadius = 60;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setSpeed(true),
      onTapUp: (_) => _setSpeed(false),
      onTapCancel: () => _setSpeed(false),
      child: Container(
        width: _buttonRadius * 2,
        height: _buttonRadius * 2,
        decoration: BoxDecoration(
          color: _isPressed
              ? Colors.black.withValues(alpha: 0.7)
              : Colors.grey.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(_buttonRadius),
        ),
        child: const Center(
          child: Icon(Icons.flash_on, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  void _setSpeed(bool isSpeeding) {
    setState(() {
      _isPressed = isSpeeding;
      widget.onSpeedChanged(isSpeeding);
    });
  }
}
