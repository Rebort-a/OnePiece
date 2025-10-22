import 'package:flutter/material.dart';

import '../base/block.dart';
import '../base/constant.dart';
import '../base/vector.dart';
import '../middle/common.dart';

class ScenePainter extends CustomPainter {
  final SceneInfo sceneInfo;
  final String debugInfo;

  // 构造函数：直接接收玩家和方块数据，无需中间Renderer
  ScenePainter(this.sceneInfo, this.debugInfo);

  @override
  void paint(Canvas canvas, Size size) {
    _render(canvas, size);
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) {
    // 玩家位置/朝向变化时重绘
    return !(oldDelegate.sceneInfo.position == sceneInfo.position) ||
        !(oldDelegate.sceneInfo.orientation == sceneInfo.orientation);
  }

  /// 绘制完整游戏场景（背景 + 方块）
  void _render(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawBlocks(canvas, size);
    _drawDebugInfo(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF87CEEB), // 天蓝色
        const Color(0xFF98D8E8), // 浅蓝色
      ],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = skyGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );
  }

  /// 绘制所有可见方块（按距离从远到近排序）
  void _drawBlocks(Canvas canvas, Size size) {
    final visibleBlocks = _getVisibleBlocks();

    // 按距离排序：远的方块先画，避免遮挡错误
    visibleBlocks.sort((a, b) {
      final distA = (a.position - sceneInfo.position).magnitudeSquare;
      final distB = (b.position - sceneInfo.position).magnitudeSquare;
      return distB.compareTo(distA);
    });

    for (final block in visibleBlocks) {
      _drawBlock(canvas, size, block);
    }
  }

  /// 筛选可见方块
  List<Block> _getVisibleBlocks() {
    return sceneInfo.blocks.where((block) {
      // 穿透性剔除
      if (block.penetrable) return false;

      // 近裁剪面剔除
      final relativePos = block.position - sceneInfo.position;
      final rotatedPos = _rotateToViewSpace(relativePos);
      return rotatedPos.z + Constants.blockSizeHalf > Constants.nearClip;
    }).toList();
  }

  /// 绘制单个方块（处理面的可见性 + 深度排序）
  void _drawBlock(Canvas canvas, Size size, Block block) {
    // 直接复用 Block 类的 getVisibleFaces 方法
    final visibleFaces = block.getVisibleFaces(sceneInfo.position);

    // 按深度排序（保持原逻辑）
    visibleFaces.sort(
      (a, b) => _getFaceDepth(
        b,
        block.position,
      ).compareTo(_getFaceDepth(a, block.position)),
    );

    for (final face in visibleFaces) {
      _drawFace(canvas, size, block, face);
    }
  }

  /// 获取方块面的深度（面中心到玩家的距离）
  double _getFaceDepth(BlockFace face, Vector3 blockPosition) {
    return (face.center - sceneInfo.position).magnitudeSquare;
  }

  /// 绘制单个方块面（投影 + 裁剪 + 多边形渲染）
  void _drawFace(Canvas canvas, Size size, Block block, BlockFace face) {
    // 获取面的原始3D顶点
    final worldVertices = face.indices
        .map((index) => block.vertices[index])
        .toList();

    // 跳过完全在视野外的面
    if (!_hasVisibleVertex(worldVertices)) return;

    // 3D顶点投影到2D屏幕
    final projected = worldVertices.map((v) => _projectPoint(v, size)).toList();

    // 过滤无效点（避免绘制不完整的多边形）
    final validPoints = projected.where((p) => p != Offset.infinite).toList();
    if (validPoints.length < 3) return;

    // 裁剪到屏幕范围内
    final clippedPoints = _clipToScreen(validPoints, size);
    if (clippedPoints.isEmpty) return;

    // 绘制最终的多边形面
    _drawPolygon(canvas, block, clippedPoints, face.normal);
  }

  /// 检查面是否至少有一个顶点在视野内（近裁剪面之后）
  bool _hasVisibleVertex(List<Vector3> vertices) {
    for (final vertex in vertices) {
      final relativePoint = vertex - sceneInfo.position;
      final rotatedPoint = _rotateToViewSpace(relativePoint);
      if (rotatedPoint.z > Constants.nearClip) return true;
    }
    return false;
  }

  /// 绘制多边形（填充颜色 + 边框，玻璃方块无边框）
  void _drawPolygon(
    Canvas canvas,
    Block block,
    List<Offset> points,
    Vector3 normal,
  ) {
    final path = Path()..addPolygon(points, true);

    // 应用光照效果（根据面的朝向调整亮度）
    final baseColor = block.type.color;
    final shadedColor = _applyLighting(baseColor, normal);

    // 填充面颜色
    canvas.drawPath(path, Paint()..color = shadedColor);

    // 非玻璃方块绘制黑色边框
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

  /// 根据面的朝向应用光照（调整亮度）
  Color _applyLighting(Color baseColor, Vector3 normal) {
    final brightness = switch ((normal.z, normal.y)) {
      (< 0, _) => 0.8, // 背面：暗一点
      (> 0, _) => 1.2, // 前面：亮一点
      (0, > 0) => 1.1, // 顶面：较亮
      (0, < 0) => 0.9, // 底面：较暗
      _ => 1.0, // 侧面（默认）：原亮度
    };

    // 调整RGB通道亮度（确保在0-1范围内）
    return baseColor.withValues(
      red: (baseColor.r * brightness).clamp(0.0, 1.0),
      green: (baseColor.g * brightness).clamp(0.0, 1.0),
      blue: (baseColor.b * brightness).clamp(0.0, 1.0),
    );
  }

  /// 3D点投影到2D屏幕（透视投影）
  Offset _projectPoint(Vector3 point, Size size) {
    final relativePoint = point - sceneInfo.position;
    final rotatedPoint = _rotateToViewSpace(relativePoint);

    // 处理近裁剪面：避免除以0或负数（导致投影异常）
    final zValue = rotatedPoint.z;
    final divisor = zValue > Constants.nearClip ? zValue : Constants.nearClip;
    final scale = Constants.focalLength / divisor;

    // 屏幕中心为原点，转换为屏幕坐标（x向右，y向上）
    final x = size.width / 2 + rotatedPoint.x * scale;
    final y = size.height / 2 - rotatedPoint.y * scale;

    return Offset(x, y);
  }

  /// 将3D点旋转到玩家视图空间（对齐玩家朝向）
  Vector3 _rotateToViewSpace(Vector3 point) {
    final forward = sceneInfo.orientation.normalized;
    final right = Vector3.up.cross(forward).normalized;
    final up = forward.cross(right).normalized;

    // 点积计算视图空间的x/y/z坐标
    return Vector3(point.dot(right), point.dot(up), point.dot(forward));
  }

  /// 裁剪多边形到屏幕范围（Sutherland-Hodgman算法）
  List<Offset> _clipToScreen(List<Offset> polygon, Size size) {
    final screen = Offset.zero & size;

    // 裁剪边界判断：是否在边界内
    bool insideLeft(Offset p) => p.dx >= screen.left;
    bool insideRight(Offset p) => p.dx <= screen.right;
    bool insideBottom(Offset p) => p.dy <= screen.bottom;
    bool insideTop(Offset p) => p.dy >= screen.top;

    // 裁剪单条边的逻辑
    List<Offset> clipEdge(
      List<Offset> input,
      bool Function(Offset) isInside,
      Offset Function(Offset, Offset) getIntersection,
    ) {
      final output = <Offset>[];
      final len = input.length;
      for (int i = 0; i < len; i++) {
        final current = input[i];
        final prev = input[(i - 1 + len) % len]; // 环形取前一个点

        final curIn = isInside(current);
        final prevIn = isInside(prev);

        if (curIn && prevIn) {
          // 两点都在内部：保留当前点
          output.add(current);
        } else if (curIn && !prevIn) {
          // 当前点在内部，前一个点在外部：添加交点 + 当前点
          output.add(getIntersection(prev, current));
          output.add(current);
        } else if (!curIn && prevIn) {
          // 当前点在外部，前一个点在内部：添加交点
          output.add(getIntersection(prev, current));
        }
        // 两点都在外部：跳过
      }
      return output;
    }

    // 计算交点：水平边界（上/下）
    Offset intersectHorizontal(Offset a, Offset b, double y) {
      final t = (y - a.dy) / (b.dy - a.dy);
      return Offset(a.dx + t * (b.dx - a.dx), y);
    }

    // 计算交点：垂直边界（左/右）
    Offset intersectVertical(Offset a, Offset b, double x) {
      final t = (x - a.dx) / (b.dx - a.dx);
      return Offset(x, a.dy + t * (b.dy - a.dy));
    }

    // 按顺序裁剪：左 → 右 → 下 → 上（确保多边形始终在屏幕内）
    List<Offset> clipped = polygon;
    clipped = clipEdge(
      clipped,
      insideLeft,
      (a, b) => intersectVertical(a, b, screen.left),
    );
    clipped = clipEdge(
      clipped,
      insideRight,
      (a, b) => intersectVertical(a, b, screen.right),
    );
    clipped = clipEdge(
      clipped,
      insideBottom,
      (a, b) => intersectHorizontal(a, b, screen.bottom),
    );
    clipped = clipEdge(
      clipped,
      insideTop,
      (a, b) => intersectHorizontal(a, b, screen.top),
    );

    return clipped;
  }

  void _drawDebugInfo(Canvas canvas, Size size) {
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      shadows: [
        Shadow(blurRadius: 2.0, color: Colors.black, offset: Offset(1.0, 1.0)),
      ],
    );

    final textSpan = TextSpan(
      text:
          'Position: (${sceneInfo.position.x.toStringAsFixed(1)}, '
          '${sceneInfo.position.y.toStringAsFixed(1)}, '
          '${sceneInfo.position.z.toStringAsFixed(1)})\n'
          'Orientation: (${sceneInfo.orientation.x.toStringAsFixed(2)}, '
          '${sceneInfo.orientation.y.toStringAsFixed(2)}, '
          '${sceneInfo.orientation.z.toStringAsFixed(2)})\n'
          'Blocks: ${sceneInfo.blocks.length}\n'
          '$debugInfo',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }
}
