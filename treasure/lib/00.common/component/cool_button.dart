import 'package:flutter/material.dart';

class CoolButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final double minWidth;
  final double height;
  final double borderRadius;
  final TextStyle textStyle;
  final double iconSize;
  final double gap;

  const CoolButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.minWidth = 200,
    this.height = 56,
    this.borderRadius = 28,
    this.textStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamily: 'Orbitron',
    ),
    this.iconSize = 20,
    this.gap = 8,
  });

  @override
  State<CoolButton> createState() => _CoolButtonState();
}

class _CoolButtonState extends State<CoolButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  // 霓虹色定义
  static const Color _neonBlue = Color(0xFF00F0FF);
  static const Color _neonPurple = Color(0xFFBF00FF);

  @override
  void initState() {
    super.initState();

    // 初始化发光动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // 发光强度动画，使用自定义曲线
    _glowAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(
        parent: _animationController,
        // 使用自定义曲线，使值越大速度越快
        curve: const SpeedCurve(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onPressed,
            child: Transform.scale(
              // 缩放动画：悬停放大，点击缩小
              scale: _isPressed
                  ? 0.95
                  : _isHovered
                  ? 1.05
                  : 1.0,
              child: Container(
                width: widget.minWidth,
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  // 蓝紫渐变背景
                  gradient: const LinearGradient(
                    colors: [_neonBlue, _neonPurple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  // 发光效果
                  boxShadow: [
                    BoxShadow(
                      color: _neonBlue,
                      blurRadius: _glowAnimation.value,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _neonPurple.withValues(alpha: 0.7),
                      blurRadius: _glowAnimation.value * 0.7,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: widget.iconSize,
                    ),
                    SizedBox(width: widget.gap),
                    Text(
                      widget.text,
                      style: widget.textStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 自定义曲线：值越大速度越快
class SpeedCurve extends Curve {
  const SpeedCurve();

  @override
  double transform(double t) {
    // t 的范围是 0.0 到 1.0
    // 当 t 接近 1.0 时（值较大），速度加快
    // 使用二次函数使曲线在末尾更陡峭，实现速度随值增大而加快的效果
    return t * t;
  }
}
