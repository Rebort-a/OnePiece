import 'package:flutter/material.dart';

class FloorBanner extends StatefulWidget {
  final String text;
  final Duration displayDuration;

  const FloorBanner({
    super.key,
    required this.text,
    this.displayDuration = const Duration(seconds: 1),
  });

  @override
  State<FloorBanner> createState() => _FloorBannerState();
}

class _FloorBannerState extends State<FloorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animationController.forward();
    Future.delayed(widget.displayDuration, _hideBanner);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _hideBanner() {
    if (!mounted) return;

    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black38, // 调整为更半透明的黑色 (15% 不透明度)
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
