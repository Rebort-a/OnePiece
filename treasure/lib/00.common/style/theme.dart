import 'dart:math';

import 'package:flutter/material.dart';

ThemeData globalTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
);

class BaseTheme {
  static const Color backgroundColor = Color(0xfff9f9f9);

  // 字体样式
  static const TextStyle titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.amberAccent,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Colors.black,
  );
}

class MagicTheme {
  // 颜色定义
  static const Color gold = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color parchment = Color(0xFFF5F1E4);
  static const Color darkParchment = Color(0xFFE8E0C7);
  static const Color magicBackground = Color(0xFF1A1409);
  static const Color cellHighlight = Color(0xFFFFF8E1);
  static const Color fixedNumber = Color(0xFF3D2B1F);
  static const Color playerNumber = Color(0xFF6B2226);
  static const Color hintColor = Color(0xFFFFECB3);

  // 字体样式
  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'Garamond',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: gold,
    shadows: [
      Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
    ],
  );

  static const TextStyle bodyStyle = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 16,
    color: parchment,
  );

  static const TextStyle numberStyle = TextStyle(
    fontFamily: 'Georgia',
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  // 魔法主题
  static ThemeData get theme => ThemeData(
    primaryColor: gold,
    canvasColor: magicBackground,
    cardColor: darkParchment.withValues(alpha: 0.9),
    textTheme: TextTheme(
      titleLarge: titleStyle,
      bodyLarge: bodyStyle,
      bodyMedium: bodyStyle,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkParchment,
        foregroundColor: fixedNumber,
        side: const BorderSide(color: gold, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontFamily: 'Garamond',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  // 羊皮纸背景
  // 修改 MagicTheme 中的 parchmentBackground
  static BoxDecoration get parchmentBackground => BoxDecoration(
    // 米黄色径向渐变：模拟羊皮纸的光影质感
    gradient: RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        MagicTheme.parchment, // 浅米黄
        MagicTheme.darkParchment, // 深米黄
        const Color(0xFFD9C8A9), // 浅棕色
      ],
    ),
    // 细微噪点：用 ImageFilter 模拟纸张纹理（无需图片）
    image: DecorationImage(
      image: const AssetImage(''), // 空图片占位（避免报错）
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.03),
        BlendMode.multiply,
      ),
      // 关键：用 CustomPaint 生成噪点（替代图片纹理）
      // 实际通过 child 中的 CustomPaint 实现，这里仅保持结构
    ),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: MagicTheme.gold, width: 2),
    boxShadow: const [
      BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(3, 3)),
    ],
  );

  // 新增：羊皮纸纹理组件（直接嵌套在需要羊皮纸效果的容器中）
  static Widget withParchmentTexture({required Widget child}) {
    return CustomPaint(painter: ParchmentTexturePainter(), child: child);
  }

  // 水晶按钮样式
  static ButtonStyle crystalButtonStyle(bool isHovered) =>
      ElevatedButton.styleFrom(
        backgroundColor: isHovered
            ? gold.withValues(alpha: 0.8)
            : darkParchment,
        foregroundColor: isHovered ? magicBackground : fixedNumber,
        side: BorderSide(
          color: isHovered ? gold : gold.withValues(alpha: 0.5),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isHovered ? 8 : 2,
        textStyle: const TextStyle(
          fontFamily: 'Garamond',
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
}

// 新增：自定义画笔，生成羊皮纸噪点纹理
class ParchmentTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    // 生成随机噪点（模拟纸张纹理）
    final random = Random();
    for (int i = 0; i < 1000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 0.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // 生成细微线条（模拟纸张纤维）
    for (int i = 0; i < 200; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + random.nextDouble() * 20;
      final endY = startY + random.nextDouble() * 5;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint..strokeWidth = 0.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
