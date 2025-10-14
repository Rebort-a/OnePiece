import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'base.dart';
import 'constant.dart';

class Manager with ChangeNotifier implements TickerProvider {
  late Ticker _ticker;
  double _lastElapsed = 0;
  final FocusNode focusNode = FocusNode();

  late final Player player;
  late CameraView lastPlayerView;
  late final List<Block> blocks;
  List<Block> _visibleBlocks = [];

  // 输入状态
  bool _forward = false;
  bool _backward = false;
  bool _left = false;
  bool _right = false;
  bool _jumping = false;
  bool _isMoving = false;

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
    lastPlayerView = player.view.copyWith();
  }

  void _initBlocks() {
    blocks = _generateTerrain();
    _updateVisibleBlocks();
  }

  // 生成简单地形
  static List<Block> _generateTerrain() {
    final blocks = <Block>[];
    final random = Random();

    // 生成地面
    for (int x = -10; x <= 10; x++) {
      for (int z = -10; z <= 10; z++) {
        final height = (random.nextDouble() * 2).floor();
        blocks.add(
          Block(
            Vector3(x.toDouble(), height.toDouble(), z.toDouble()),
            BlockType.grass,
          ),
        );

        // 添加地下方块
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

    // 添加一些随机方块作为障碍物
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

  // 更新可见方块缓存
  void _updateVisibleBlocks() {
    if (lastPlayerView.equals(player.view)) return;

    lastPlayerView = player.view.copyWith();

    _visibleBlocks = blocks.where((block) {
      if (block.penetrable) return false;

      // 距离裁剪：只显示一定范围内的方块
      final distance = (block.position - player.position).magnitude;
      if (distance > Constant.renderDistance) return false;

      // 视锥体粗略裁剪：只显示玩家前方的方块
      final relativePos = block.position - player.position;
      final rotatedPos = relativePos.rotateY(-player.yaw);
      return rotatedPos.z > 0;
    }).toList();

    // 按距离排序，远处的先绘制
    _visibleBlocks.sort((a, b) {
      final distA = (a.position - player.position).magnitude;
      final distB = (b.position - player.position).magnitude;
      return distB.compareTo(distA);
    });
  }

  void _initFocusNode() {
    focusNode.requestFocus();
  }

  void _initTicker() {
    _ticker = createTicker(_update);
    _ticker.start();
  }

  // 更新游戏状态
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
    if (_jumping) {
      player.jump();
      _jumping = false;
    }

    // 更新玩家状态
    player.update(deltaTime, blocks);

    // 更新可见方块缓存
    _updateVisibleBlocks();

    notifyListeners();
  }

  void _handleMovement(double deltaTime) {
    Vector3 moveDirection = Vector3.zero;

    if (_forward) moveDirection += player.forward;
    if (_backward) moveDirection -= player.forward;
    if (_right) moveDirection += player.right;
    if (_left) moveDirection -= player.right;

    _isMoving = moveDirection.magnitude > 0;

    if (_isMoving) {
      player.move(moveDirection, Constant.moveSpeed, deltaTime);
    } else {
      // 停止移动时逐渐减速
      player.velocity = Vector3(
        player.velocity.x * 0.8,
        player.velocity.y,
        player.velocity.z * 0.8,
      );
    }
  }

  // 处理键盘事件
  void handleKeyEvent(KeyEvent event) {
    bool isKeyUp = event is KeyUpEvent;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        _forward = !isKeyUp;
        break;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        _backward = !isKeyUp;
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        _left = !isKeyUp;
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        _right = !isKeyUp;
        break;
      case LogicalKeyboardKey.space:
        _jumping = !isKeyUp;
        break;
    }
  }

  // 处理触摸旋转开始
  void handleTouchStart(DragStartDetails details) {
    _lastTouchPos = details.localPosition;
  }

  // 处理触摸旋转移动
  void handleTouchMove(DragUpdateDetails details) {
    if (_lastTouchPos != null) {
      final delta = details.localPosition - _lastTouchPos!;
      _lastTouchPos = details.localPosition;

      player.rotate(
        delta.dx * Constant.touchSensitivity,
        delta.dy * Constant.touchSensitivity,
      );
      notifyListeners();
    }
  }

  // 处理触摸旋转结束
  void handleTouchEnd(DragEndDetails details) {
    _lastTouchPos = null;
  }

  // 处理移动控制（移动端虚拟摇杆）
  void setMovement(double horizontal, double vertical) {
    _forward = vertical > 0;
    _backward = vertical < 0;
    _left = horizontal < 0;
    _right = horizontal > 0;
  }

  void setStop() {
    _forward = false;
    _backward = false;
    _left = false;
    _right = false;
  }

  // 处理跳跃按钮（移动端）
  void triggerJump() {
    _jumping = true;
  }

  // 处理鼠标移动事件
  void handleMouseHover(PointerHoverEvent event) {
    if (focusNode.hasFocus) {
      player.rotate(
        event.delta.dx * Constant.touchSensitivity,
        event.delta.dy * Constant.touchSensitivity,
      );
      notifyListeners();
    }
  }

  // 获取可见方块（用于绘制）
  List<Block> get visibleBlocks => _visibleBlocks;

  bool get isMoving => _isMoving;
}
