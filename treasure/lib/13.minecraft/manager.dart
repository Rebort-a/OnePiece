import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:math';
import 'base.dart';

class Manager with ChangeNotifier implements TickerProvider {
  late Ticker _ticker;
  double _lastElapsed = 0; // 上次更新时间
  final FocusNode focusNode = FocusNode();

  late final Player player;
  late final List<Block> blocks;
  late final double moveSpeed;
  late final double lookSensitivity;

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
    _initData();
    _initPlayer();
    _initBlocks();
    _initFocusNode();
    _initTicker();
  }

  void _initFocusNode() {
    focusNode.requestFocus();
  }

  void _initTicker() {
    _ticker = createTicker(_update);
    _ticker.start();
  }

  void _initData() {
    moveSpeed = 50.0;
    lookSensitivity = 0.002;
  }

  void _initPlayer() {
    player = Player(position: Vector3(0, 2, 5));
  }

  void _initBlocks() {
    blocks = _generateTerrain();
  }

  // 生成简单地形
  static List<Block> _generateTerrain() {
    final blocks = <Block>[];
    final random = Random();

    // 生成地面
    for (int x = -10; x <= 10; x++) {
      for (int z = -10; z <= 10; z++) {
        // 随机高度变化
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

  // 更新游戏状态
  void _update(Duration elapsed) {
    final currentTime = elapsed.inMilliseconds;

    final currentElapsed = currentTime / 1000.0;
    final deltaTime = currentElapsed - _lastElapsed;
    _lastElapsed = currentElapsed;

    final clampedDeltaTime = deltaTime.clamp(0.004, 0.02); // 限制帧率

    // 处理移动输入
    Vector3 moveDirection = Vector3(0, 0, 0);

    if (_forward) moveDirection += player.forward;
    if (_backward) moveDirection -= player.forward;
    if (_right) moveDirection += player.right;
    if (_left) moveDirection -= player.right;

    _isMoving = moveDirection.magnitude > 0;

    if (_isMoving) {
      player.move(moveDirection, moveSpeed, clampedDeltaTime);
    } else {
      // 停止移动时逐渐减速
      player.velocity = Vector3(
        player.velocity.x * 0.8,
        player.velocity.y,
        player.velocity.z * 0.8,
      );
    }

    // 处理跳跃
    if (_jumping) {
      player.jump();
      _jumping = false; // 防止连续跳跃
    }

    // 更新玩家状态
    player.update(clampedDeltaTime, blocks);

    notifyListeners();
  }

  // 处理键盘事件
  void handleKeyEvent(KeyEvent event) {
    bool isKeyUp = event is KeyUpEvent;
    switch (event.logicalKey) {
      // 上方向：上箭头、W/w
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        _forward = !isKeyUp;
        break;
      // 下方向：下箭头、S/s
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        _backward = !isKeyUp;
        break;
      // 左方向：左箭头、A/a
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        _left = !isKeyUp;
        break;
      // 右方向：右箭头、D/d
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        _right = !isKeyUp;
        break;
      // 空格
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

      // 水平和垂直旋转
      player.rotate(-delta.dx * lookSensitivity, -delta.dy * lookSensitivity);

      notifyListeners();
    }
  }

  // 处理触摸旋转结束
  void handleTouchEnd(DragEndDetails details) {
    _lastTouchPos = null;
  }

  // 处理移动控制（移动端虚拟摇杆）
  void setMovement(bool forward, bool left) {
    _forward = forward;
    _backward = !forward;
    _left = left;
    _right = !left;
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
    // 只有窗口获得焦点时才处理鼠标移动
    if (focusNode.hasFocus) {
      // 使用delta值计算视角旋转
      player.rotate(
        -event.delta.dx * lookSensitivity,
        -event.delta.dy * lookSensitivity,
      );
      notifyListeners();
    }
  }

  // 获取玩家是否在移动
  bool get isMoving => _isMoving;
}
