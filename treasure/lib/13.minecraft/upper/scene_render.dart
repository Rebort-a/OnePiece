import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../base/block.dart';
import '../base/constant.dart';
import '../base/matrix.dart';
import '../base/vector.dart';
import '../middle/common.dart';

/// 渲染调试配置
class RenderDebugConfig {
  /// 是否启用近裁剪面剔除
  bool enableNearClip = true;

  /// 是否启用背面剔除
  bool enableBackfaceCulling = true;

  /// 是否启用深度排序
  bool enableDepthSorting = true;

  /// 是否启用屏幕裁剪
  bool enableScreenClipping = true;

  /// 是否显示调试信息
  bool showDebugInfo = false;

  /// 是否显示面法向量
  bool showFaceNormals = false;

  /// 是否显示顶点坐标
  bool showVertexPositions = false;
}

/// 场景渲染器（重构版）
class ScenePainter extends CustomPainter {
  final SceneInfo sceneInfo;
  final String debugInfo;
  final RenderDebugConfig debugConfig;

  ScenePainter(this.sceneInfo, this.debugInfo, {RenderDebugConfig? debugConfig})
    : debugConfig = debugConfig ?? RenderDebugConfig();

  @override
  void paint(Canvas canvas, Size size) {
    _renderScene(canvas, size);
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) {
    return oldDelegate.sceneInfo.position != sceneInfo.position ||
        oldDelegate.sceneInfo.orientation != sceneInfo.orientation ||
        oldDelegate.debugConfig != debugConfig;
  }

  // ===========================================================================
  // 主渲染流程
  // ===========================================================================

  /// 主渲染入口
  void _renderScene(Canvas canvas, Size size) {
    // 步骤1: 绘制天空背景
    _drawSkyBackground(canvas, size);

    // 步骤2: 渲染所有3D几何体
    _render3DGeometry(canvas, size);

    // 步骤3: 绘制调试信息
    if (debugConfig.showDebugInfo) {
      _drawDebugOverlay(canvas, size);
    } else {
      _drawPositionDisplay(canvas, size);
    }
  }

  /// 渲染3D几何体
  void _render3DGeometry(Canvas canvas, Size size) {
    // 2.1 获取可见方块
    final visibleBlocks = _getVisibleBlocks();
    if (visibleBlocks.isEmpty) return;

    // 2.2 深度排序
    final sortedBlocks = _sortBlocksByDepth(visibleBlocks);

    // 2.3 渲染每个方块
    for (final block in sortedBlocks) {
      _renderSingleBlock(canvas, size, block);
    }
  }

  // ===========================================================================
  // 步骤1: 背景渲染
  // ===========================================================================

  /// 绘制天空背景
  void _drawSkyBackground(Canvas canvas, Size size) {
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF87CEEB), const Color(0xFF98D8E8)],
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = skyGradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height),
        ),
    );
  }

  // ===========================================================================
  // 步骤2: 可见性处理
  // ===========================================================================

  /// 获取可见方块（应用近裁剪面剔除）
  List<Block> _getVisibleBlocks() {
    return sceneInfo.blocks.where((block) {
      if (!debugConfig.enableNearClip) return true;

      // 近裁剪面剔除：检查方块是否在近裁剪面之后
      final relativePos = block.position.toVector3() - sceneInfo.position;
      final viewSpacePos = _transformToViewSpace(relativePos);
      return viewSpacePos.z + Constants.blockSizeHalf > Constants.nearClip;
    }).toList();
  }

  /// 按深度排序方块（从远到近）
  List<Block> _sortBlocksByDepth(List<Block> blocks) {
    if (!debugConfig.enableDepthSorting) return blocks;

    blocks.sort((a, b) {
      final distA =
          (a.position.toVector3() - sceneInfo.position).magnitudeSquare;
      final distB =
          (b.position.toVector3() - sceneInfo.position).magnitudeSquare;
      return distB.compareTo(distA); // 远到近排序
    });
    return blocks;
  }

  // ===========================================================================
  // 步骤3: 单个方块渲染
  // ===========================================================================

  /// 渲染单个方块
  void _renderSingleBlock(Canvas canvas, Size size, Block block) {
    // 3.1 获取可见面
    final visibleFaces = _getVisibleFaces(block);
    if (visibleFaces.isEmpty) return;

    // 3.2 按深度排序面
    final sortedFaces = _sortFacesByDepth(
      visibleFaces,
      block.position.toVector3(),
    );

    // 3.3 渲染每个面
    for (final face in sortedFaces) {
      _renderBlockFace(canvas, size, block, face);
    }
  }

  /// 获取可见面（应用背面剔除）
  List<BlockFace> _getVisibleFaces(Block block) {
    if (!debugConfig.enableBackfaceCulling) {
      return block.faces;
    } else {
      return block.getVisibleFaces(sceneInfo.position);
    }
  }

  /// 按深度排序面
  List<BlockFace> _sortFacesByDepth(
    List<BlockFace> faces,
    Vector3 blockPosition,
  ) {
    if (!debugConfig.enableDepthSorting) return faces;

    faces.sort((a, b) {
      final depthA = _calculateFaceDepth(a, blockPosition);
      final depthB = _calculateFaceDepth(b, blockPosition);
      return depthB.compareTo(depthA); // 远到近排序
    });
    return faces;
  }

  /// 计算面深度
  double _calculateFaceDepth(BlockFace face, Vector3 blockPosition) {
    return (face.center - sceneInfo.position).magnitudeSquare;
  }

  // ===========================================================================
  // 步骤4: 单个面渲染
  // ===========================================================================

  /// 渲染方块面
  void _renderBlockFace(Canvas canvas, Size size, Block block, BlockFace face) {
    // 4.1 获取面的3D顶点
    final worldVertices = _getFaceVertices(block, face);

    // 4.2 投影到2D屏幕
    final screenVertices = _projectVerticesToScreen(worldVertices, size);

    // 4.3 裁剪到屏幕范围
    final clippedVertices = _clipToScreenBounds(screenVertices, size);
    if (clippedVertices.length < 3) return;

    // 4.4 绘制多边形
    _drawPolygonFace(canvas, block, clippedVertices, face.normal);

    // 4.5 绘制调试信息
    if (debugConfig.showFaceNormals) {
      _drawFaceNormal(canvas, size, face, block.position.toVector3());
    }
  }

  /// 获取面的3D顶点
  List<Vector3> _getFaceVertices(Block block, BlockFace face) {
    return face.indices.map((index) => block.vertices[index]).toList();
  }

  /// 投影顶点到屏幕空间
  List<Offset> _projectVerticesToScreen(List<Vector3> vertices, Size size) {
    return vertices.map((vertex) => _project3DTo2D(vertex, size)).toList();
  }

  /// 裁剪到屏幕边界
  List<Offset> _clipToScreenBounds(List<Offset> vertices, Size size) {
    if (!debugConfig.enableScreenClipping) {
      return vertices.where((v) => v != Offset.infinite).toList();
    }
    return _clipPolygonToScreen(vertices, size);
  }

  // ===========================================================================
  // 核心数学运算
  // ===========================================================================

  /// 3D点投影到2D屏幕（透视投影）
  // Offset _project3DTo2D(Vector3 point, Size size) {
  //   final relativePoint = point - sceneInfo.position;
  //   final rotatedPoint = _transformToViewSpace(relativePoint);

  //   // 处理近裁剪面：避免除以0或负数（导致投影异常）
  //   final zValue = rotatedPoint.z;
  //   final divisor = zValue > Constants.nearClip ? zValue : Constants.nearClip;
  //   final scale = Constants.focalLength / divisor;

  //   // 屏幕中心为原点，转换为屏幕坐标（x向右，y向上）
  //   final x = size.width / 2 + rotatedPoint.x * scale;
  //   final y = size.height / 2 - rotatedPoint.y * scale;

  //   return Offset(x, y);
  // }

  /// 3D到2D投影变换
  Offset _project3DTo2D(Vector3 point, Size size) {
    // 构建视图投影矩阵
    final viewMatrix = Matrix.lookAtLH(
      sceneInfo.position,
      sceneInfo.position + sceneInfo.orientation.normalized,
      Vector3Unit.up,
    );

    final projectionMatrix = Matrix.perspectiveLH(
      Constants.fieldOfView * math.pi / 180,
      size.width / size.height,
      Constants.nearClip,
      Constants.farClip,
    );

    final vpMatrix = projectionMatrix.multiply(viewMatrix);
    final worldPoint = Vector4(point.x, point.y, point.z, 1.0);
    final clipPoint = vpMatrix.multiplyVector4(worldPoint);

    double ndcX, ndcY;

    if (clipPoint.w <= 0) {
      // 处理相机后面的点
      final w = 0.001; // 避免除零
      ndcX = clipPoint.x / w;
      ndcY = clipPoint.y / w;
    } else {
      // 正常透视除法
      ndcX = clipPoint.x / clipPoint.w;
      ndcY = clipPoint.y / clipPoint.w;
    }

    final screenX =
        (ndcX * Constants.ndcScale + Constants.ndcOffset) * size.width;
    final screenY =
        (Constants.screenYFlip -
            (ndcY * Constants.ndcScale + Constants.ndcOffset)) *
        size.height;

    return Offset(screenX, screenY);
  }

  /// 变换到视图空间（用于可见性判断）
  Vector3 _transformToViewSpace(Vector3 point) {
    final forward = sceneInfo.orientation.normalized;
    final right = Vector3.up.cross(forward).normalized;
    final up = forward.cross(right).normalized;

    return Vector3(
      point.dot(right), // X: 右方向
      point.dot(up), // Y: 上方向
      point.dot(forward), // Z: 前方向（深度）
    );
  }

  // ===========================================================================
  // 绘制操作
  // ===========================================================================

  /// 绘制多边形面
  void _drawPolygonFace(
    Canvas canvas,
    Block block,
    List<Offset> vertices,
    Vector3 normal,
  ) {
    final path = Path()..addPolygon(vertices, true);

    // 应用光照
    final baseColor = block.type.color;
    final shadedColor = _applyFaceLighting(baseColor, normal);

    // 填充面
    canvas.drawPath(path, Paint()..color = shadedColor);

    // 绘制边框（非透明方块）
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

  /// 应用面光照
  Color _applyFaceLighting(Color baseColor, Vector3 normal) {
    final brightness = switch ((normal.z, normal.y)) {
      (< 0, _) => Constants.lightingBackFace, // 背面
      (> 0, _) => Constants.lightingFrontFace, // 正面
      (0, > 0) => Constants.lightingTopFace, // 顶面
      (0, < 0) => Constants.lightingBottomFace, // 底面
      _ => Constants.lightingDefault, // 侧面
    };

    return baseColor.withValues(
      red: (baseColor.r * brightness).clamp(0.0, 1.0),
      green: (baseColor.g * brightness).clamp(0.0, 1.0),
      blue: (baseColor.b * brightness).clamp(0.0, 1.0),
    );
  }

  // ===========================================================================
  // 调试功能
  // ===========================================================================

  /// 绘制调试信息覆盖层
  void _drawDebugOverlay(Canvas canvas, Size size) {
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      shadows: [
        Shadow(blurRadius: 2.0, color: Colors.black, offset: Offset(1.0, 1.0)),
      ],
    );

    final debugText =
        '''
Position: (${sceneInfo.position.x.toStringAsFixed(1)}, ${sceneInfo.position.y.toStringAsFixed(1)}, ${sceneInfo.position.z.toStringAsFixed(1)})
Orientation: (${sceneInfo.orientation.x.toStringAsFixed(2)}, ${sceneInfo.orientation.y.toStringAsFixed(2)}, ${sceneInfo.orientation.z.toStringAsFixed(2)})
Blocks: ${sceneInfo.blocks.length} (Visible: ${_getVisibleBlocks().length})
Near Clip: ${debugConfig.enableNearClip ? 'ON' : 'OFF'}
Backface Cull: ${debugConfig.enableBackfaceCulling ? 'ON' : 'OFF'}
Depth Sort: ${debugConfig.enableDepthSorting ? 'ON' : 'OFF'}
Screen Clip: ${debugConfig.enableScreenClipping ? 'ON' : 'OFF'}
$debugInfo
''';

    final textSpan = TextSpan(text: debugText, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  /// 绘制Position坐标（黑色圆角背景+垂直排列）
  void _drawPositionDisplay(Canvas canvas, Size size) {
    // 1. 构建坐标文本（垂直排列x/y/z）
    final position = sceneInfo.position;
    final posText =
        '''X: ${position.x.toStringAsFixed(1)}
Y: ${position.y.toStringAsFixed(1)}
Z: ${position.z.toStringAsFixed(1)}''';

    // 2. 配置文本样式（白色清晰显示）
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.2, // 行高，优化垂直间距
    );

    // 3. 测量文本尺寸（用于计算背景大小）
    final textSpan = TextSpan(text: posText, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 3, // 固定3行，避免异常换行
    );
    textPainter.layout(); // 执行测量

    // 4. 配置显示参数（边缘间距+内边距+圆角）
    const edgeTopMargin = 32.0; // 距离窗口边缘的距离
    const edgeLeftMargin = 10.0;
    const paddingH = 8.0; // 文本水平内边距
    const paddingV = 4.0; // 文本垂直内边距
    const radius = 4.0; // 圆角半径

    // 5. 计算背景矩形位置和大小
    final bgWidth = textPainter.width + paddingH * 2;
    final bgHeight = textPainter.height + paddingV * 2;
    final bgRect = Rect.fromLTWH(
      edgeLeftMargin, // 左边缘间距
      edgeTopMargin, // 上边缘间距
      bgWidth,
      bgHeight,
    );

    // 6. 绘制黑色圆角背景
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, Radius.circular(radius)),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    // 7. 绘制文本（居中对齐背景）
    textPainter.paint(
      canvas,
      Offset(
        edgeLeftMargin + paddingH, // 文本水平偏移（边缘间距+内边距）
        edgeTopMargin + paddingV, // 文本垂直偏移（边缘间距+内边距）
      ),
    );
  }

  /// 绘制面法向量（调试用）
  void _drawFaceNormal(
    Canvas canvas,
    Size size,
    BlockFace face,
    Vector3 blockPosition,
  ) {
    final faceCenter = _project3DTo2D(face.center, size);
    final normalEnd = _project3DTo2D(face.center + face.normal * 0.5, size);

    canvas.drawLine(
      faceCenter,
      normalEnd,
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );
  }

  // ===========================================================================
  // 裁剪算法（Sutherland-Hodgman）
  // ===========================================================================

  List<Offset> _clipPolygonToScreen(List<Offset> polygon, Size size) {
    final screen = Offset.zero & size;
    List<Offset> clipped = polygon;

    // 定义裁剪边界判断函数
    bool insideLeft(Offset p) => p.dx >= screen.left;
    bool insideRight(Offset p) => p.dx <= screen.right;
    bool insideBottom(Offset p) => p.dy <= screen.bottom;
    bool insideTop(Offset p) => p.dy >= screen.top;

    // 裁剪左边界
    clipped = _clipPolygonEdge(
      clipped,
      insideLeft,
      (a, b) => _intersectVertical(a, b, screen.left),
    );
    // 裁剪右边界
    clipped = _clipPolygonEdge(
      clipped,
      insideRight,
      (a, b) => _intersectVertical(a, b, screen.right),
    );
    // 裁剪下边界
    clipped = _clipPolygonEdge(
      clipped,
      insideBottom,
      (a, b) => _intersectHorizontal(a, b, screen.bottom),
    );
    // 裁剪上边界
    clipped = _clipPolygonEdge(
      clipped,
      insideTop,
      (a, b) => _intersectHorizontal(a, b, screen.top),
    );

    return clipped;
  }

  List<Offset> _clipPolygonEdge(
    List<Offset> input,
    bool Function(Offset) isInside,
    Offset Function(Offset, Offset) getIntersection,
  ) {
    final output = <Offset>[];
    final len = input.length;

    for (int i = 0; i < len; i++) {
      final current = input[i];
      final prev = input[(i - 1 + len) % len];

      final curIn = isInside(current);
      final prevIn = isInside(prev);

      if (curIn && prevIn) {
        output.add(current);
      } else if (curIn && !prevIn) {
        output.add(getIntersection(prev, current));
        output.add(current);
      } else if (!curIn && prevIn) {
        output.add(getIntersection(prev, current));
      }
    }

    return output;
  }

  Offset _intersectHorizontal(Offset a, Offset b, double y) {
    final t = (y - a.dy) / (b.dy - a.dy);
    return Offset(a.dx + t * (b.dx - a.dx), y);
  }

  Offset _intersectVertical(Offset a, Offset b, double x) {
    final t = (x - a.dx) / (b.dx - a.dx);
    return Offset(x, a.dy + t * (b.dy - a.dy));
  }
}
