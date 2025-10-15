import 'package:flutter/material.dart';

import 'base.dart';
import 'constant.dart';
import 'manager.dart';
import 'widget.dart';

/// 主游戏页面
class MinecraftPage extends StatelessWidget {
  final GameManager gameManager = GameManager();

  MinecraftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 游戏场景
          _buildGameScene(),

          // 十字准星
          const Crosshair(),

          // 输入处理
          _buildInputHandler(),

          // 移动端控制
          _buildMobileControls(),
        ],
      ),
    );
  }

  /// 构建游戏场景
  Widget _buildGameScene() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: gameManager,
          builder: (context, child) {
            return CustomPaint(
              painter: GamePainter(
                gameManager.player,
                gameManager.visibleBlocks,
              ),
              size: constraints.biggest,
            );
          },
        );
      },
    );
  }

  /// 构建输入处理器
  Widget _buildInputHandler() {
    final inputHandler = gameManager.inputHandler;

    return KeyboardListener(
      focusNode: inputHandler.focusNode,
      onKeyEvent: inputHandler.handleKeyEvent,
      child: MouseRegion(
        cursor: SystemMouseCursors.none,
        onHover: inputHandler.handleMouseHover,
        child: GestureDetector(
          onPanStart: inputHandler.handleTouchStart,
          onPanUpdate: inputHandler.handleTouchMove,
          onPanEnd: inputHandler.handleTouchEnd,
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  /// 构建移动端控制
  Widget _buildMobileControls() {
    final inputHandler = gameManager.inputHandler;

    return MobileControls(
      onMove: inputHandler.setMobileMove,
      onJump: inputHandler.setMobileJump,
    );
  }
}

/// 游戏绘制器
class GamePainter extends CustomPainter {
  final Player player;
  final List<Block> blocks;
  late final GameRenderer _renderer;

  GamePainter(this.player, this.blocks) {
    _renderer = GameRenderer(player, blocks);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _renderer.render(canvas, size);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return !oldDelegate.player.position.equals(player.position) ||
        oldDelegate.blocks.length != blocks.length;
  }
}

/// 方块面信息
class BlockFace {
  final List<int> vertexIndices;
  final Vector3 normal;
  final Vector3 center;

  BlockFace(this.vertexIndices, this.normal, this.center);
}

/// 游戏渲染器
class GameRenderer {
  final Player player;
  final List<Block> blocks;

  GameRenderer(this.player, this.blocks);

  /// 绘制游戏场景
  void render(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawBlocks(canvas, size);
  }

  /// 绘制背景（天空和地面）
  void _drawBackground(Canvas canvas, Size size) {
    final sinPitch = player.pitchSin;
    const angleScale = 0.8;
    final horizonOffset = -(sinPitch / angleScale) * (size.height / 2);
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

  /// 绘制所有方块
  void _drawBlocks(Canvas canvas, Size size) {
    final visibleBlocks = _getVisibleBlocks();

    // 按距离排序（从远到近）
    visibleBlocks.sort((a, b) {
      final distA = (a.position - player.position).magnitude;
      final distB = (b.position - player.position).magnitude;
      return distB.compareTo(distA);
    });

    for (final block in visibleBlocks) {
      _drawBlock(canvas, size, block);
    }
  }

  /// 获取可见方块
  List<Block> _getVisibleBlocks() {
    return blocks.where((block) {
      if (block.penetrable) return false;

      final relativePos = block.position - player.position;
      final rotatedPos = _rotateToViewSpace(relativePos);

      return rotatedPos.z > 0;
    }).toList();
  }

  /// 绘制单个方块
  void _drawBlock(Canvas canvas, Size size, Block block) {
    final faces = _getBlockFaces(block.position);
    final visibleFaces = faces
        .where((face) => _isFaceVisible(face, block.position))
        .toList();

    // 按深度排序（从远到近）
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

  /// 获取方块的所有面
  List<BlockFace> _getBlockFaces(Vector3 position) {
    return [
      BlockFace(
        [0, 1, 2, 3],
        Vector3(0, 0, -1),
        position + Vector3(0, 0, -0.5),
      ),
      BlockFace([4, 5, 6, 7], Vector3(0, 0, 1), position + Vector3(0, 0, 0.5)),
      BlockFace([1, 5, 6, 2], Vector3(1, 0, 0), position + Vector3(0.5, 0, 0)),
      BlockFace(
        [4, 0, 3, 7],
        Vector3(-1, 0, 0),
        position + Vector3(-0.5, 0, 0),
      ),
      BlockFace([3, 2, 6, 7], Vector3(0, 1, 0), position + Vector3(0, 0.5, 0)),
      BlockFace(
        [0, 4, 5, 1],
        Vector3(0, -1, 0),
        position + Vector3(0, -0.5, 0),
      ),
    ];
  }

  /// 检查面是否可见
  bool _isFaceVisible(BlockFace face, Vector3 blockPosition) {
    final toCamera = (player.position - face.center).normalized;
    return face.normal.dot(toCamera) > 0;
  }

  /// 获取面的深度
  double _getFaceDepth(BlockFace face, Vector3 blockPosition) {
    return (face.center - player.position).magnitude;
  }

  /// 绘制方块面
  void _drawFace(Canvas canvas, Size size, Block block, BlockFace face) {
    // 获取面的原始顶点
    final worldVertices = face.vertexIndices
        .map((index) => block.vertices[index])
        .toList();

    // 检查面是否至少有一个顶点在视野内
    if (!_hasVisibleVertex(worldVertices)) {
      return;
    }

    // 投影所有顶点到2D屏幕（不进行近裁剪面裁剪）
    final projected = worldVertices.map((v) => _projectPoint(v, size)).toList();

    // 检查是否有有效点
    final validPoints = projected.where((p) => p != Offset.infinite).toList();
    if (validPoints.length < 3) return;

    // 裁剪到屏幕范围
    final clippedPoints = _clipToScreen(validPoints, size);
    if (clippedPoints.isEmpty) return;

    _drawPolygon(canvas, block, clippedPoints, face.normal);
  }

  /// 检查面是否至少有一个顶点在视野内
  bool _hasVisibleVertex(List<Vector3> vertices) {
    for (final vertex in vertices) {
      final relativePoint = vertex - player.position;
      final rotatedPoint = _rotateToViewSpace(relativePoint);

      // 如果顶点在近裁剪面之后，就认为可见
      if (rotatedPoint.z > Constants.nearClip) {
        return true;
      }
    }
    return false;
  }

  /// 绘制多边形
  void _drawPolygon(
    Canvas canvas,
    Block block,
    List<Offset> points,
    Vector3 normal,
  ) {
    final path = Path()..addPolygon(points, true);

    final baseColor = block.color;
    final shadedColor = _applyLighting(baseColor, normal);

    canvas.drawPath(path, Paint()..color = shadedColor);

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

  /// 应用光照效果
  Color _applyLighting(Color baseColor, Vector3 normal) {
    final brightness = switch ((normal.z, normal.y)) {
      (< 0, _) => 0.8, // 背面
      (> 0, _) => 1.2, // 正面
      (0, > 0) => 1.1, // 顶面（z=0时判断y）
      (0, < 0) => 0.9, // 底面（z=0时判断y）
      _ => 1.0, // 默认亮度（如侧面z=0且y=0）
    };

    return baseColor.withValues(
      red: (baseColor.r * brightness).clamp(0.0, 1.0),
      green: (baseColor.g * brightness).clamp(0.0, 1.0),
      blue: (baseColor.b * brightness).clamp(0.0, 1.0),
    );
  }

  /// 3D到2D投影
  Offset _projectPoint(Vector3 point, Size size) {
    final relativePoint = point - player.position;
    final rotatedPoint = _rotateToViewSpace(relativePoint);

    // 处理近裁剪面之前的情况
    final zValue = rotatedPoint.z;
    final divisor = zValue > Constants.nearClip ? zValue : Constants.nearClip;
    final scale = Constants.focalLength / divisor;

    final x = size.width / 2 + rotatedPoint.x * scale;
    final y = size.height / 2 - rotatedPoint.y * scale;

    return Offset(x, y);
  }

  /// 旋转到视图空间
  Vector3 _rotateToViewSpace(Vector3 point) {
    final forward = player.orientation.normalized;
    final right = Vector3.up.cross(forward).normalized;
    final up = forward.cross(right).normalized;

    return Vector3(point.dot(right), point.dot(up), point.dot(forward));
  }

  /// 裁剪多边形到屏幕范围
  List<Offset> _clipToScreen(List<Offset> polygon, Size size) {
    final Rect screen = Offset.zero & size;

    // 定义裁剪边界（左、右、下、上）
    bool insideLeft(Offset p) => p.dx >= screen.left;
    bool insideRight(Offset p) => p.dx <= screen.right;
    bool insideBottom(Offset p) => p.dy <= screen.bottom;
    bool insideTop(Offset p) => p.dy >= screen.top;

    // Sutherland-Hodgman 裁剪函数
    List<Offset> clipEdge(
      List<Offset> input,
      bool Function(Offset) inside,
      Offset Function(Offset, Offset) intersect,
    ) {
      final output = <Offset>[];
      final len = input.length;
      for (int i = 0; i < len; i++) {
        final current = input[i];
        final prev = input[(i - 1 + len) % len];

        final curIn = inside(current);
        final prevIn = inside(prev);

        if (curIn && prevIn) {
          output.add(current);
        } else if (curIn && !prevIn) {
          output.add(intersect(prev, current));
          output.add(current);
        } else if (!curIn && prevIn) {
          output.add(intersect(prev, current));
        }
      }
      return output;
    }

    // 插值交点函数
    Offset intersectHorizontal(Offset a, Offset b, double y) {
      final t = (y - a.dy) / (b.dy - a.dy);
      return Offset(a.dx + t * (b.dx - a.dx), y);
    }

    Offset intersectVertical(Offset a, Offset b, double x) {
      final t = (x - a.dx) / (b.dx - a.dx);
      return Offset(x, a.dy + t * (b.dy - a.dy));
    }

    // 裁剪顺序：左 -> 右 -> 下 -> 上
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
}
