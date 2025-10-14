import 'dart:math';
import 'package:flutter/material.dart';

import 'base.dart';
import 'manager.dart';
import 'widget.dart';

class MinecraftPage extends StatelessWidget {
  final Manager manager = Manager();

  MinecraftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 游戏场景
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedBuilder(
                animation: manager,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GamePainter(manager.player, manager.visibleBlocks),
                    size: constraints.biggest,
                  );
                },
              );
            },
          ),

          // 输入层 - 处理触摸和键盘事件
          KeyboardListener(
            focusNode: manager.focusNode,
            onKeyEvent: manager.handleKeyEvent,
            child: MouseRegion(
              cursor: SystemMouseCursors.none,
              onHover: manager.handleMouseHover,
              child: GestureDetector(
                onPanStart: manager.handleTouchStart,
                onPanUpdate: manager.handleTouchMove,
                onPanEnd: manager.handleTouchEnd,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // 十字准星
          const Crosshair(),

          // 移动端控制按钮
          MobileControls(
            onMovement: manager.setMovement,
            onStop: manager.setStop,
            onJump: manager.triggerJump,
          ),
        ],
      ),
    );
  }
}

// 游戏场景绘制器
class GamePainter extends CustomPainter {
  final Player player;
  final List<Block> blocks;
  static const double focalLength = 300;
  static const double nearClip = 0.1; // 近裁剪面

  GamePainter(this.player, this.blocks);

  // 3D点投影到2D屏幕
  Offset project(Vector3 point, Size size) {
    final relativePoint = point - player.position;
    final rotatedPoint = relativePoint
        .rotateY(-player.yaw)
        .rotateX(-player.pitch);

    // 修正：Z轴正方向为前方，所以 rotatedPoint.z > 0 表示在玩家前方
    // 添加近裁剪面检查
    if (rotatedPoint.z <= nearClip) return Offset.infinite;

    final scale = focalLength / rotatedPoint.z;
    final x = size.width / 2 + rotatedPoint.x * scale;
    final y = size.height / 2 - rotatedPoint.y * scale;

    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawBlocks(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final angleBase = pi * 0.26;
    final horizonOffset = -(player.pitch / angleBase) * (size.height / 2);
    final horizonY = (size.height / 2) + horizonOffset;
    final clampedHorizonY = horizonY.clamp(-size.height, size.height * 2);

    // 绘制天空
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, clampedHorizonY),
      Paint()..color = const Color(0xFF87CEEB),
    );

    // 绘制地面
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        clampedHorizonY,
        size.width,
        size.height - clampedHorizonY,
      ),
      Paint()..color = const Color(0xFF795548),
    );
  }

  void _drawBlocks(Canvas canvas, Size size) {
    for (final block in blocks) {
      _drawBlock(canvas, size, block);
    }
  }

  // 绘制单个方块
  void _drawBlock(Canvas canvas, Size size, Block block) {
    final vertices = _getBlockVertices(block.position);
    final projected = vertices.map((v) => project(v, size)).toList();

    // 检查是否所有点都在视野外
    if (projected.every((p) => p == Offset.infinite)) return;

    // 定义方块的6个面及其法向量
    final faces = [
      _Face([0, 1, 2, 3], Vector3(0, 0, -1)), // 前面 (Z负方向)
      _Face([4, 5, 6, 7], Vector3(0, 0, 1)), // 后面 (Z正方向)
      _Face([1, 5, 6, 2], Vector3(1, 0, 0)), // 右面 (X正方向)
      _Face([4, 0, 3, 7], Vector3(-1, 0, 0)), // 左面 (X负方向)
      _Face([3, 2, 6, 7], Vector3(0, 1, 0)), // 上面 (Y正方向)
      _Face([0, 4, 5, 1], Vector3(0, -1, 0)), // 下面 (Y负方向)
    ];

    // 绘制每个可见面
    for (final face in faces) {
      if (_isFaceVisible(face, block.position)) {
        _drawFace(canvas, block, face, projected);
      }
    }
  }

  List<Vector3> _getBlockVertices(Vector3 position) {
    return [
      // 前面 vertices (Z负方向)
      Vector3(position.x - 0.5, position.y - 0.5, position.z - 0.5),
      Vector3(position.x + 0.5, position.y - 0.5, position.z - 0.5),
      Vector3(position.x + 0.5, position.y + 0.5, position.z - 0.5),
      Vector3(position.x - 0.5, position.y + 0.5, position.z - 0.5),
      // 后面 vertices (Z正方向)
      Vector3(position.x - 0.5, position.y - 0.5, position.z + 0.5),
      Vector3(position.x + 0.5, position.y - 0.5, position.z + 0.5),
      Vector3(position.x + 0.5, position.y + 0.5, position.z + 0.5),
      Vector3(position.x - 0.5, position.y + 0.5, position.z + 0.5),
    ];
  }

  bool _isFaceVisible(_Face face, Vector3 blockPosition) {
    // 简化的可见性检查：使用相机到面的向量与面法向量的点积
    final faceCenter = blockPosition + face.normal * 0.5;
    final toCamera = (player.position - faceCenter).normalized;

    // 如果法向量与到相机方向的点积为正，表示面朝向相机
    return face.normal.dot(toCamera) > 0;
  }

  void _drawFace(
    Canvas canvas,
    Block block,
    _Face face,
    List<Offset> projected,
  ) {
    // 检查面是否有有效的投影点
    bool hasValidPoints = false;
    final validPoints = <Offset>[];

    for (int i = 0; i < face.indices.length; i++) {
      final point = projected[face.indices[i]];
      if (point != Offset.infinite) {
        validPoints.add(point);
        hasValidPoints = true;
      }
    }

    if (!hasValidPoints || validPoints.length < 3) return;

    // 创建路径
    final path = Path();
    path.moveTo(validPoints[0].dx, validPoints[0].dy);

    for (int i = 1; i < validPoints.length; i++) {
      path.lineTo(validPoints[i].dx, validPoints[i].dy);
    }

    path.close();

    // 绘制面
    final paint = Paint()..color = _getFaceColor(block.color, face.normal);
    canvas.drawPath(path, paint);

    // 绘制边框（玻璃不绘制边框）
    if (block.type != BlockType.glass) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black38
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  Color _getFaceColor(Color baseColor, Vector3 normal) {
    // 根据面的朝向调整颜色亮度，增加立体感
    double brightness = 1.0;

    if (normal.z < 0) {
      brightness = 0.8; // 前面：暗化
    } else if (normal.z > 0) {
      brightness = 1.2; // 后面：亮化
    } else if (normal.y > 0) {
      brightness = 1.1; // 上面：稍亮
    } else if (normal.y < 0) {
      brightness = 0.9; // 下面：稍暗
    }

    return Color.fromARGB(
      (baseColor.a * 255.0).round() & 0xff, // 替换 alpha
      ((baseColor.r * 255.0) * brightness).clamp(0, 255).toInt() &
          0xff, // 替换 red
      ((baseColor.g * 255.0) * brightness).clamp(0, 255).toInt() &
          0xff, // 替换 green
      ((baseColor.b * 255.0) * brightness).clamp(0, 255).toInt() &
          0xff, // 替换 blue
    );
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return !oldDelegate.player.position.equals(player.position) ||
        oldDelegate.player.yaw != player.yaw ||
        oldDelegate.player.pitch != player.pitch ||
        oldDelegate.blocks.length != blocks.length;
  }
}

// 面的数据类
class _Face {
  final List<int> indices;
  final Vector3 normal;

  _Face(this.indices, this.normal);
}
