import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'base.dart';
import 'constant.dart';

/// 游戏管理器
class GameManager with ChangeNotifier implements TickerProvider {
  late final Ticker _ticker;
  late double _lastTime;

  late final Player player;
  late final List<Block> blocks;
  late final Octree octree;
  late final InputHandler inputHandler;
  late final WorldGenerator worldGenerator;

  Vector3 _lastPlayerPos = Vector3.zero;
  Vector3 _lastPlayerOrientation = Vector3.zero;
  List<Block> _visibleBlocks = [];

  GameManager() {
    _initialize();
  }

  /// 初始化游戏
  void _initialize() {
    worldGenerator = WorldGenerator();
    blocks = worldGenerator.generateTerrain();

    final worldBounds = worldGenerator.calculateWorldBounds(blocks);
    octree = Octree(worldBounds);
    octree.insertAll(blocks);

    player = Player(position: Vector3(0, 2, 5));
    inputHandler = InputHandler(player, FocusNode()..requestFocus());

    _lastPlayerPos = player.position;
    _lastPlayerOrientation = player.orientation;

    _updateVisibleBlocks();
    _startGameLoop();
  }

  /// 开始游戏循环
  void _startGameLoop() {
    _lastTime = 0;
    _ticker = createTicker(_update);
    _ticker.start();
  }

  /// 游戏更新循环
  void _update(Duration elapsed) {
    final currentTime = elapsed.inMilliseconds / 1000.0;
    final deltaTime = (currentTime - _lastTime).clamp(
      Constants.minDeltaTime,
      Constants.maxDeltaTime,
    );
    _lastTime = currentTime;

    inputHandler.updatePlayerMovement(deltaTime);
    player.update(deltaTime, blocks);
    _updateVisibleBlocks();

    notifyListeners();
  }

  /// 更新可见方块
  void _updateVisibleBlocks() {
    if (_lastPlayerPos.equals(player.position) &&
        _lastPlayerOrientation.equals(player.orientation)) {
      return;
    }

    _lastPlayerPos = player.position;
    _lastPlayerOrientation = player.orientation;

    // 使用八叉树查询可能可见的方块
    final candidates = octree.querySphere(
      player.position,
      Constants.renderDistance,
    );

    // 过滤可见方块
    _visibleBlocks = candidates.where((block) {
      if (block.penetrable) return false;
      final relativePos = block.position - player.position;
      final rotatedPos = _rotateToViewSpace(relativePos);
      return rotatedPos.z > 0;
    }).toList();

    notifyListeners();
  }

  /// 旋转到视图空间
  Vector3 _rotateToViewSpace(Vector3 point) {
    final forward = player.orientation.normalized;
    final right = Vector3.up.cross(forward).normalized;
    final up = forward.cross(right).normalized;

    return Vector3(point.dot(right), point.dot(up), point.dot(forward));
  }

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  /// 清理资源
  @override
  void dispose() {
    _ticker.stop();
    inputHandler.focusNode.dispose();
    super.dispose();
  }

  // 公开属性
  List<Block> get visibleBlocks => _visibleBlocks;
  FocusNode get focusNode => inputHandler.focusNode;
  bool get isMoving => inputHandler.isMoving;
}

/// 输入处理器
class InputHandler {
  final Player player;
  final FocusNode focusNode;

  Vector2 _moveInput = Vector2.zero;
  bool _jumpRequested = false;
  Offset? _lastTouchPos;

  InputHandler(this.player, this.focusNode);

  /// 处理键盘事件
  void handleKeyEvent(KeyEvent event) {
    final isKeyUp = event is KeyUpEvent;
    final key = event.logicalKey;

    switch (key) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        _moveInput = _moveInput.appointY(isKeyUp ? 0.0 : 1.0);
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        _moveInput = _moveInput.appointY(isKeyUp ? 0.0 : -1.0);
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        _moveInput = _moveInput.appointX(isKeyUp ? 0.0 : -1.0);
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        _moveInput = _moveInput.appointX(isKeyUp ? 0.0 : 1.0);
        break;
      case LogicalKeyboardKey.space:
        if (!isKeyUp) _jumpRequested = true;
        break;
    }
  }

  /// 处理触摸开始
  void handleTouchStart(DragStartDetails details) {
    _lastTouchPos = details.localPosition;
  }

  /// 处理触摸移动
  void handleTouchMove(DragUpdateDetails details) {
    if (_lastTouchPos != null) {
      final delta = details.localPosition - _lastTouchPos!;
      _lastTouchPos = details.localPosition;

      player.rotateView(
        delta.dx * Constants.touchSensitivity,
        -delta.dy * Constants.touchSensitivity,
      );
    }
  }

  /// 处理触摸结束
  void handleTouchEnd(DragEndDetails details) {
    _lastTouchPos = null;
  }

  /// 处理鼠标悬停
  void handleMouseHover(PointerHoverEvent event) {
    if (focusNode.hasFocus) {
      player.rotateView(
        event.delta.dx * Constants.mouseSensitivity,
        event.delta.dy * Constants.mouseSensitivity,
      );
    }
  }

  /// 移动端移动输入
  void setMobileMove(Vector2 input) {
    _moveInput = input;
  }

  /// 移动端跳跃输入
  void setMobileJump() {
    _jumpRequested = true;
  }

  /// 更新玩家移动
  void updatePlayerMovement(double deltaTime) {
    if (!_moveInput.isZero) {
      player.move(_moveInput, Constants.moveSpeed);
    } else {
      // 平滑减速
      player.velocity = Vector3(
        player.velocity.x * 0.8,
        player.velocity.y,
        player.velocity.z * 0.8,
      );
    }

    if (_jumpRequested) {
      player.jump();
      _jumpRequested = false;
    }
  }

  /// 获取移动状态
  bool get isMoving => !_moveInput.isZero;
}

/// 世界生成器
class WorldGenerator {
  final Random _random = Random();

  /// 生成地形
  List<Block> generateTerrain() {
    final blocks = <Block>[];

    // 生成基础地形
    for (int x = -10; x <= 10; x++) {
      for (int z = -10; z <= 10; z++) {
        final height = (_random.nextDouble() * 2).floor();

        // 地表方块（草地）
        blocks.add(
          Block(
            Vector3(x.toDouble(), height.toDouble(), z.toDouble()),
            BlockType.grass,
          ),
        );

        // 地下方块（泥土）
        for (int y = 0; y < height; y++) {
          blocks.add(
            Block(
              Vector3(x.toDouble(), y.toDouble() - 1, z.toDouble()),
              BlockType.dirt,
            ),
          );
        }
      }
    }

    // 生成随机结构
    for (int i = 0; i < 15; i++) {
      final x = (_random.nextDouble() * 20 - 10).floor();
      final z = (_random.nextDouble() * 20 - 10).floor();
      final y = (_random.nextDouble() * 3 + 1).floor();

      final type = _random.nextDouble() > 0.5
          ? BlockType.stone
          : BlockType.wood;
      blocks.add(
        Block(Vector3(x.toDouble(), y.toDouble(), z.toDouble()), type),
      );
    }

    return blocks;
  }

  /// 计算世界边界
  AABB calculateWorldBounds(List<Block> blocks) {
    double minX = double.infinity,
        minY = double.infinity,
        minZ = double.infinity;
    double maxX = -double.infinity,
        maxY = -double.infinity,
        maxZ = -double.infinity;

    for (final block in blocks) {
      minX = min(minX, block.position.x);
      minY = min(minY, block.position.y);
      minZ = min(minZ, block.position.z);
      maxX = max(maxX, block.position.x);
      maxY = max(maxY, block.position.y);
      maxZ = max(maxZ, block.position.z);
    }

    // 添加边界余量
    return AABB(
      Vector3(minX - 1, minY - 1, minZ - 1),
      Vector3(maxX + 1, maxY + 1, maxZ + 1),
    );
  }
}
