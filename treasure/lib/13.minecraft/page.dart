import 'package:flutter/material.dart';

import 'base.dart';
import 'constant.dart';
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
                    painter: ImprovedGamePainter(
                      manager.player,
                      manager.visibleBlocks,
                    ),
                    size: constraints.biggest,
                  );
                },
              );
            },
          ),

          // 十字准星
          const Crosshair(),

          // 主机端控制方式，键盘控制移动和跳跃，鼠标移动转动视角
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

          // 移动端控制方式，屏幕按键移动和跳跃，滑动屏幕转动视角
          MobileControls(
            onDrag: manager.mobileMove,
            onJump: manager.mobileJump,
          ),
        ],
      ),
    );
  }
}

// 改进的游戏场景绘制器
class ImprovedGamePainter extends CustomPainter {
  final Player player;
  final List<Block> blocks;

  ImprovedGamePainter(this.player, this.blocks);

  // 改进的投影方法 - 更宽松的检查
  Offset project(Vector3 point, Size size) {
    final relativePoint = point - player.position;
    final rotatedPoint = _rotateToViewSpace(relativePoint);

    // 只做近平面裁剪，但更智能
    if (rotatedPoint.z <= Constant.nearClip) {
      // 不直接返回 infinite，而是尝试修复靠近近平面的点
      final fixedZ = Constant.nearClip + 0.01;
      final scale = Constant.focalLength / fixedZ;
      final x = size.width / 2 + rotatedPoint.x * scale;
      final y = size.height / 2 - rotatedPoint.y * scale;

      // 检查是否在合理屏幕范围内
      if (x.abs() > size.width * 3 || y.abs() > size.height * 3) {
        return Offset.infinite;
      }
      return Offset(x, y);
    }

    // 正常投影
    final scale = Constant.focalLength / rotatedPoint.z;
    final x = size.width / 2 + rotatedPoint.x * scale;
    final y = size.height / 2 - rotatedPoint.y * scale;

    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawBlocks(canvas, size);
  }

  Vector3 _rotateToViewSpace(Vector3 point) {
    final forward = player.orientation.normalized;
    final right = Vector3.up.cross(forward).normalized;
    final up = forward.cross(right).normalized;

    return Vector3(point.dot(right), point.dot(up), point.dot(forward));
  }

  void _drawBackground(Canvas canvas, Size size) {
    final sinP = player.pitchSin;
    const angleScale = 0.8;
    final horizonOffset = -(sinP / angleScale) * (size.height / 2);
    final horizonY = (size.height / 2) + horizonOffset;
    final clampedHorizonY = horizonY.clamp(-size.height, size.height * 2);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, clampedHorizonY),
      Paint()..color = const Color(0xFF87CEEB),
    );

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

  void _drawBlock(Canvas canvas, Size size, Block block) {
    final vertices = _getBlockVertices(block.position);
    final projected = vertices.map((v) => project(v, size)).toList();

    // 检查是否有任何有效的点（比原来宽松）
    final hasValidPoints = projected.any((p) => p != Offset.infinite);
    if (!hasValidPoints) return;

    final faces = [
      _Face([0, 1, 2, 3], Vector3(0, 0, -1)), // 前
      _Face([4, 5, 6, 7], Vector3(0, 0, 1)), // 后
      _Face([1, 5, 6, 2], Vector3(1, 0, 0)), // 右
      _Face([4, 0, 3, 7], Vector3(-1, 0, 0)), // 左
      _Face([3, 2, 6, 7], Vector3(0, 1, 0)), // 上
      _Face([0, 4, 5, 1], Vector3(0, -1, 0)), // 下
    ];

    // 只剔除背面，不过度检查
    final visibleFaces = faces.where((face) {
      return _isFaceVisible(face, block.position);
    }).toList();

    // 按深度排序（从远到近）
    visibleFaces.sort((a, b) {
      final depthA = _getFaceDepth(a, block.position);
      final depthB = _getFaceDepth(b, block.position);
      return depthB.compareTo(depthA);
    });

    for (final face in visibleFaces) {
      _drawFaceImproved(canvas, block, face, projected);
    }
  }

  List<Vector3> _getBlockVertices(Vector3 position) {
    return [
      Vector3(position.x - 0.5, position.y - 0.5, position.z - 0.5),
      Vector3(position.x + 0.5, position.y - 0.5, position.z - 0.5),
      Vector3(position.x + 0.5, position.y + 0.5, position.z - 0.5),
      Vector3(position.x - 0.5, position.y + 0.5, position.z - 0.5),
      Vector3(position.x - 0.5, position.y - 0.5, position.z + 0.5),
      Vector3(position.x + 0.5, position.y - 0.5, position.z + 0.5),
      Vector3(position.x + 0.5, position.y + 0.5, position.z + 0.5),
      Vector3(position.x - 0.5, position.y + 0.5, position.z + 0.5),
    ];
  }

  bool _isFaceVisible(_Face face, Vector3 blockPosition) {
    final faceCenter = blockPosition + face.normal * 0.5;
    final toCamera = (player.position - faceCenter).normalized;
    return face.normal.dot(toCamera) > 0;
  }

  double _getFaceDepth(_Face face, Vector3 blockPosition) {
    final faceCenter = blockPosition + face.normal * 0.5;
    return (faceCenter - player.position).magnitude;
  }

  // 改进的面绘制方法 - 处理部分顶点无效的情况
  void _drawFaceImproved(
    Canvas canvas,
    Block block,
    _Face face,
    List<Offset> projected,
  ) {
    final validPoints = <Offset>[];
    final validIndices = <int>[];

    // 收集有效点及其原始索引
    for (int i = 0; i < face.indices.length; i++) {
      final point = projected[face.indices[i]];
      if (point != Offset.infinite) {
        validPoints.add(point);
        validIndices.add(i);
      }
    }

    // 需要至少3个点才能形成面
    if (validPoints.length < 3) return;

    // 如果所有点都有效，直接绘制四边形
    if (validPoints.length == 4) {
      _drawQuadrilateral(canvas, block, validPoints);
    } else {
      // 部分点无效，绘制多边形
      _drawPolygon(canvas, block, validPoints);
    }
  }

  // 绘制四边形（正常情况）
  void _drawQuadrilateral(Canvas canvas, Block block, List<Offset> points) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    final paint = Paint()
      ..color = _getFaceColor(block.color, Vector3.zero); // 简化颜色计算
    canvas.drawPath(path, paint);

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

  // 绘制多边形（处理顶点缺失情况）
  void _drawPolygon(Canvas canvas, Block block, List<Offset> points) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    // 使用基础颜色（简化）
    final baseColor = block.color;
    final paint = Paint()..color = baseColor;
    canvas.drawPath(path, paint);

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
    double brightness = 1.0;

    if (normal.z < 0) {
      brightness = 0.8;
    } else if (normal.z > 0) {
      brightness = 1.2;
    } else if (normal.y > 0) {
      brightness = 1.1;
    } else if (normal.y < 0) {
      brightness = 0.9;
    }

    return Color.fromARGB(
      (baseColor.a * 255.0).round() & 0xff,
      ((baseColor.r * 255.0) * brightness).clamp(0, 255).toInt() & 0xff,
      ((baseColor.g * 255.0) * brightness).clamp(0, 255).toInt() & 0xff,
      ((baseColor.b * 255.0) * brightness).clamp(0, 255).toInt() & 0xff,
    );
  }

  @override
  bool shouldRepaint(covariant ImprovedGamePainter oldDelegate) {
    return !oldDelegate.player.position.equals(player.position) ||
        oldDelegate.blocks.length != blocks.length;
  }
}

// 投影点包装类
class ProjectedPoint {
  final Offset offset;
  final bool isOnScreen;

  bool get isValid => offset != Offset.infinite;

  const ProjectedPoint(this.offset, this.isOnScreen);
}

class _Face {
  final List<int> indices;
  final Vector3 normal;

  _Face(this.indices, this.normal);
}
