import 'package:flutter/material.dart';
import 'dart:ui';

class GlassContainer extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final double? maxWidth;
  final double? maxHeight;
  final double? minWidth;
  final double? minHeight;
  final BorderRadiusGeometry borderRadius;
  final double blurStrength;

  final bool enableFloat;
  final double floatOffset;
  final Duration animationDuration;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth,
    this.maxHeight,
    this.minWidth,
    this.minHeight,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blurStrength = 8,
    this.enableFloat = true,
    this.floatOffset = 20,
    this.animationDuration = const Duration(seconds: 6),
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      value: 0.0,
    );

    _floatAnimation =
        Tween<double>(
          begin: -widget.floatOffset / 2,
          end: widget.floatOffset / 2,
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.linear),
        );

    if (widget.enableFloat) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: child,
          );
        },
        child: _buildStaticContent(),
      ),
    );
  }

  Widget _buildStaticContent() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth ?? double.infinity,
        maxHeight: widget.maxHeight ?? double.infinity,
        minWidth: widget.minWidth ?? 0,
        minHeight: widget.minHeight ?? 0,
      ),

      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurStrength,
            sigmaY: widget.blurStrength,
            tileMode: TileMode.mirror,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: widget.borderRadius,
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
