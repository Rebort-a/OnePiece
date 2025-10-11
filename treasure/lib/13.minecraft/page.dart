import 'dart:math';

import 'package:flutter/material.dart';
import '../00.common/component/bool_button.dart';
import '../00.common/component/joystick_component.dart';
import 'base.dart';
import 'manager.dart';

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
                    painter: GamePainter(manager.player, manager.blocks),
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
              onHover: (details) => manager.handleMouseHover(details),
              child: GestureDetector(
                onPanStart: manager.handleTouchStart,
                onPanUpdate: manager.handleTouchMove,
                onPanEnd: manager.handleTouchEnd,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // 十字准星
          Crosshair(),

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

    // 绘制十字准星
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 2 / 3),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width / 3, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MobileControls extends StatelessWidget {
  final Function(bool, bool) onMovement;
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
          child: Joystick(
            onDirectionChanged: _handleJoystickMove,
            onStop: _handleJoystickStop,
          ),
        ),

        // 右侧：跳跃按钮
        Positioned(
          right: 20,
          bottom: 20,
          child: BoolButton(icon: Icons.arrow_upward, onChanged: _handleJump),
        ),
      ],
    );
  }

  // 处理摇杆方向变化（将弧度转换为移动方向）
  void _handleJoystickMove(double radians) {
    // 计算x/z方向的移动分量（基于弧度）
    // 注意：游戏中通常X为左右方向，Z为前后方向
    final x = cos(radians); // 水平方向（左右）
    final z = sin(radians); // 前后方向

    // 标准化向量（确保斜向移动速度不超过正向移动）
    final magnitude = sqrt(x * x + z * z);
    if (magnitude > 0) {
      onMovement(z / magnitude < 0, x / magnitude < 0);
    }
  }

  // 处理摇杆停止（停止移动）
  void _handleJoystickStop() {
    onStop();
  }

  // 处理跳跃（仅在按下时触发一次跳跃）
  void _handleJump(bool isDown) {
    if (isDown) {
      onJump();
    }
  }
}

// 游戏场景绘制器
class GamePainter extends CustomPainter {
  final Player player;
  final List<Block> blocks;
  final double focalLength = 300;

  GamePainter(this.player, this.blocks);

  // 3D点投影到2D屏幕
  Offset project(Vector3 point, Size size) {
    // 转换到玩家局部坐标系（考虑旋转）
    final relativePoint = point - player.position;
    final rotatedPoint = relativePoint
        .rotateY(-player.yaw)
        .rotateX(-player.pitch);

    // 透视投影
    if (rotatedPoint.z >= 0) return Offset.infinite; // 在玩家后方的点不绘制

    final scale = focalLength / (-rotatedPoint.z);
    final x = size.width / 2 + rotatedPoint.x * scale;
    final y = size.height / 2 - rotatedPoint.y * scale;

    return Offset(x, y);
  }

  // 获取投影后的大小
  double getProjectedSize(Vector3 point, Size size, double originalSize) {
    final relativePoint = point - player.position;
    final rotatedPoint = relativePoint
        .rotateY(-player.yaw)
        .rotateX(-player.pitch);

    if (rotatedPoint.z >= 0) return 0;

    return originalSize * (focalLength / (-rotatedPoint.z));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 调整地平线偏移比例，增强灵敏度
    // 缩小角度基数，让相同角度产生更大偏移
    final angleBase = pi * 0.26;
    final horizonOffset = (player.pitch / angleBase) * (size.height / 2);

    // 计算地平线位置并限制在屏幕外范围（-size.height到size.height*2）
    // 确保大角度时地平线完全移出屏幕
    final horizonY = (size.height / 2) + horizonOffset;
    final double clampedHorizonY = horizonY.clamp(
      -size.height,
      size.height * 2,
    );

    // 绘制天空背景（从顶部到地平线）
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, clampedHorizonY),
      Paint()..color = Color(0xFF87CEEB),
    );

    // 绘制地面背景（从地平线到底部）
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        clampedHorizonY,
        size.width,
        size.height - clampedHorizonY,
      ),
      Paint()..color = Color(0xFF795548),
    );

    // 筛选可见方块并按距离排序（远处的先绘制）
    final visibleBlocks = blocks.where((block) {
      if (!block.isSolid) return false;
      final relativePoint = block.position - player.position;
      return relativePoint.rotateY(-player.yaw).z < 0; // 在玩家前方
    }).toList();

    // 按距离排序，远处的先绘制
    visibleBlocks.sort((a, b) {
      final distA = (a.position - player.position).magnitude;
      final distB = (b.position - player.position).magnitude;
      return distB.compareTo(distA);
    });

    // 绘制方块
    for (final block in visibleBlocks) {
      _drawBlock(canvas, size, block);
    }
  }

  // 绘制单个方块
  void _drawBlock(Canvas canvas, Size size, Block block) {
    // 获取方块的8个顶点
    final vertices = [
      // 前面
      Vector3(
        block.position.x - 0.5,
        block.position.y - 0.5,
        block.position.z - 0.5,
      ),
      Vector3(
        block.position.x + 0.5,
        block.position.y - 0.5,
        block.position.z - 0.5,
      ),
      Vector3(
        block.position.x + 0.5,
        block.position.y + 0.5,
        block.position.z - 0.5,
      ),
      Vector3(
        block.position.x - 0.5,
        block.position.y + 0.5,
        block.position.z - 0.5,
      ),

      // 后面
      Vector3(
        block.position.x - 0.5,
        block.position.y - 0.5,
        block.position.z + 0.5,
      ),
      Vector3(
        block.position.x + 0.5,
        block.position.y - 0.5,
        block.position.z + 0.5,
      ),
      Vector3(
        block.position.x + 0.5,
        block.position.y + 0.5,
        block.position.z + 0.5,
      ),
      Vector3(
        block.position.x - 0.5,
        block.position.y + 0.5,
        block.position.z + 0.5,
      ),
    ];

    // 投影所有顶点
    final projected = vertices.map((v) => project(v, size)).toList();

    // 检查是否所有点都在视野外
    if (projected.every((p) => p == Offset.infinite)) return;

    // 定义方块的6个面
    final faces = [
      // 前面 (z-)
      [0, 1, 2, 3],
      // 后面 (z+)
      [4, 5, 6, 7],
      // 右面 (x+)
      [1, 5, 6, 2],
      // 左面 (x-)
      [4, 0, 3, 7],
      // 上面 (y+)
      [3, 2, 6, 7],
      // 下面 (y-)
      [0, 4, 5, 1],
    ];

    // 绘制每个面
    for (int faceIndex = 0; faceIndex < faces.length; faceIndex++) {
      final face = faces[faceIndex]; // 当前面的顶点索引列表

      // 检查面是否可见（至少有一个点可见）
      if (face.any((i) => projected[i] != Offset.infinite)) {
        // 创建路径
        final path = Path();
        path.moveTo(projected[face[0]].dx, projected[face[0]].dy);

        for (int i = 1; i < face.length; i++) {
          if (projected[face[i]] != Offset.infinite) {
            path.lineTo(projected[face[i]].dx, projected[face[i]].dy);
          }
        }

        path.close();

        // 创建画笔（基础颜色）
        final paint = Paint()..color = block.color;

        // 添加深度感（阴影）- 使用索引判断面类型

        if (faceIndex == 0) {
          // 前面（z-）：暗化
          final alpha = (block.color.a * 255.0).round() & 0xff;
          final red = (block.color.r * 255.0).round() & 0xff;
          final green = (block.color.g * 255.0).round() & 0xff;
          final blue = (block.color.b * 255.0).round() & 0xff;

          paint.color = Color.fromARGB(
            alpha,
            (red * 0.8).clamp(0, 255).toInt(),
            (green * 0.8).clamp(0, 255).toInt(),
            (blue * 0.8).clamp(0, 255).toInt(),
          );
        } else if (faceIndex == 1) {
          // 后面（z+）：亮化
          final alpha = (block.color.a * 255.0).round() & 0xff;
          final red = (block.color.r * 255.0).round() & 0xff;
          final green = (block.color.g * 255.0).round() & 0xff;
          final blue = (block.color.b * 255.0).round() & 0xff;

          paint.color = Color.fromARGB(
            alpha,
            (red * 1.2).clamp(0, 255).toInt(),
            (green * 1.2).clamp(0, 255).toInt(),
            (blue * 1.2).clamp(0, 255).toInt(),
          );
        }

        // 绘制面
        canvas.drawPath(path, paint);

        // 绘制边框
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
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return !oldDelegate.player.position.equals(player.position) ||
        oldDelegate.player.yaw != player.yaw ||
        oldDelegate.player.pitch != player.pitch ||
        oldDelegate.blocks.length != blocks.length;
  }
}
