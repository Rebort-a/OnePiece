import 'package:flutter/material.dart';
import 'dart:ui'; // 需要导入dart:ui以使用ImageFilter

/// 玻璃态容器 - 支持根据内容自适应大小
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double? maxWidth;
  final double? maxHeight;
  final double? minWidth;
  final double? minHeight;
  final BorderRadiusGeometry borderRadius;
  final double blurStrength;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.maxWidth,
    this.maxHeight,
    this.minWidth,
    this.minHeight,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blurStrength = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
        maxHeight: maxHeight ?? double.infinity,
        minWidth: minWidth ?? 0,
        minHeight: minHeight ?? 0,
      ),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurStrength,
                sigmaY: blurStrength,
              ),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: borderRadius,
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
