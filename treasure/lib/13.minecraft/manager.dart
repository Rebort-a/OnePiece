import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'base.dart';
import 'constant.dart';

class Manager with ChangeNotifier implements TickerProvider {
  late Ticker _ticker;
  late double _lastElapsed;
  late final FocusNode focusNode;

  late final Player player;
  late Vector3 lastPosition;
  late Vector3 lastOrientation;

  late final List<Block> blocks;
  List<Block> _visibleBlocks = [];

  // 输入状态 - 使用向量控制
  Vector2 _moveInput = Vector2.zero;
  bool _isJumpRequested = false;

  // 用于触摸控制
  Offset? _lastTouchPos;

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  Manager() {
    _initPlayer();
    _initBlocks();
    _initFocusNode();
    _initTicker();
  }

  void _initPlayer() {
    player = Player(position: Vector3(0, 2, 5));
    lastPosition = player.position;
    lastOrientation = player.orientation;
  }

  void _initBlocks() {
    blocks = _generateTerrain();
    _updateVisibleBlocks();
  }

  static List<Block> _generateTerrain() {
    final blocks = <Block>[];
    final random = Random();

    for (int x = -10; x <= 10; x++) {
      for (int z = -10; z <= 10; z++) {
        final height = (random.nextDouble() * 2).floor();
        blocks.add(
          Block(
            Vector3(x.toDouble(), height.toDouble(), z.toDouble()),
            BlockType.grass,
          ),
        );

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

    for (int i = 0; i < 15; i++) {
      final x = (random.nextDouble() * 20 - 10).floor();
      final z = (random.nextDouble() * 20 - 10).floor();
      final y = (random.nextDouble() * 3 + 1).floor();

      blocks.add(
        Block(
          Vector3(x.toDouble(), y.toDouble(), z.toDouble()),
          random.nextDouble() > 0.5 ? BlockType.stone : BlockType.wood,
        ),
      );
    }

    return blocks;
  }

  void _updateVisibleBlocks() {
    if (lastPosition.equals(player.position) &&
        lastOrientation.equals(player.orientation)) {
      return;
    }

    lastPosition = player.position;
    lastOrientation = player.orientation;

    // 使用原来的宽松检查
    _visibleBlocks = blocks.where((block) {
      if (block.penetrable) return false;

      final distance = (block.position - player.position).magnitude;
      if (distance > Constant.renderDistance) return false;

      // 原来的简单可见性检查
      final relativePos = block.position - player.position;
      final rotatedPos = _rotateToViewSpace(relativePos);

      return rotatedPos.z > 0; // 只检查是否在相机前方
    }).toList();

    _visibleBlocks.sort((a, b) {
      final distA = (a.position - player.position).magnitude;
      final distB = (b.position - player.position).magnitude;
      return distB.compareTo(distA);
    });
  }

  Vector3 _rotateToViewSpace(Vector3 point) {
    final direction = player.orientation.normalized;

    // 计算右向量：上向量(0,1,0)与前向向量的叉积
    final right = Vector3.up.cross(direction).normalized;

    // 计算实际上向量：前向向量与右向量的叉积
    final up = direction.cross(right).normalized;

    // 构造视图旋转矩阵
    return Vector3(
      point.dot(right), // x分量：右方向
      point.dot(up), // y分量：上方向
      point.dot(direction), // z分量：前方向
    );
  }

  void _initFocusNode() {
    focusNode = FocusNode()..requestFocus();
  }

  void _initTicker() {
    _lastElapsed = 0;
    _ticker = createTicker(_update);
    _ticker.start();
  }

  void _update(Duration elapsed) {
    final currentTime = elapsed.inMilliseconds;
    final currentElapsed = currentTime / 1000.0;
    final deltaTime = (currentElapsed - _lastElapsed).clamp(
      Constant.minDeltaTime,
      Constant.maxDeltaTime,
    );
    _lastElapsed = currentElapsed;

    // 处理移动输入
    _handleMovement(deltaTime);

    // 处理跳跃
    if (_isJumpRequested) {
      player.jump();
      _isJumpRequested = false;
    }

    player.update(deltaTime, blocks);
    _updateVisibleBlocks();
    notifyListeners();
  }

  void _handleMovement(double deltaTime) {
    if (!_moveInput.isZero) {
      player.move(_moveInput, Constant.moveSpeed);
    } else {
      // 平滑减速
      player.velocity = Vector3(
        player.velocity.x * 0.8,
        player.velocity.y,
        player.velocity.z * 0.8,
      );
    }
  }

  // 处理键盘事件
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
        if (!isKeyUp) {
          _isJumpRequested = true;
        }

        break;
    }
  }

  void handleTouchStart(DragStartDetails details) {
    _lastTouchPos = details.localPosition;
  }

  void handleTouchMove(DragUpdateDetails details) {
    if (_lastTouchPos != null) {
      final delta = details.localPosition - _lastTouchPos!;
      _lastTouchPos = details.localPosition;

      player.rotateView(
        delta.dx * Constant.touchSensitivity,
        -delta.dy * Constant.touchSensitivity,
      );
      notifyListeners();
    }
  }

  void handleTouchEnd(DragEndDetails details) {
    _lastTouchPos = null;
  }

  // 设置移动输入向量
  void mobileMove(Vector2 input) {
    _moveInput = input;
  }

  void mobileJump() {
    _isJumpRequested = true;
  }

  void handleMouseHover(PointerHoverEvent event) {
    if (focusNode.hasFocus) {
      player.rotateView(
        event.delta.dx * Constant.mouseSensitivity,
        event.delta.dy * Constant.mouseSensitivity,
      );
      notifyListeners();
    }
  }

  List<Block> get visibleBlocks => _visibleBlocks;
  bool get isMoving => !_moveInput.isZero;
}
