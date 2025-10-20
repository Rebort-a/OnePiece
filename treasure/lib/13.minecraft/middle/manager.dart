import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../base/block.dart';
import '../base/constant.dart';
import '../base/player.dart';
import '../base/vector.dart';
import 'chunk_manager.dart';
import 'control_manager.dart';
import 'world_generator.dart';

/// 游戏状态
class GameState {
  final Vector3 playerPosition;
  final Vector3 playerOrientation;
  final List<Block> visibleBlocks;

  const GameState({
    required this.playerPosition,
    required this.playerOrientation,
    required this.visibleBlocks,
  });
}

/// 游戏管理器
class Manager with ChangeNotifier implements TickerProvider {
  late final Ticker _ticker;
  late double _lastTime;

  late final Player player;
  late final ControlManager controlManager;
  late final ChunkManager chunkManager;

  GameState _lastState = const GameState(
    playerPosition: Vector3.zero,
    playerOrientation: Vector3.zero,
    visibleBlocks: [],
  );

  List<Block> _visibleBlocks = [];

  Manager() {
    _initialize();
  }

  /// 初始化游戏
  void _initialize() {
    chunkManager = ChunkManager(WorldGenerator());
    player = Player(position: Vector3(0, 20, 5));
    controlManager = ControlManager(player);

    _updateVisibleBlocks();
    _startGameLoop();
  }

  /// 开始游戏循环
  void _startGameLoop() {
    _lastTime = 0;
    _ticker = createTicker(_update);
    _ticker.start();
  }

  /// 游戏更新
  void _update(Duration elapsed) {
    final currentTime = elapsed.inMilliseconds / 1000.0;
    final deltaTime = (currentTime - _lastTime).clamp(
      Constants.minDeltaTime,
      Constants.maxDeltaTime,
    );
    _lastTime = currentTime;

    // 更新输入和物理
    controlManager.updatePlayerMovement(deltaTime);
    _updatePhysics(deltaTime);

    // 更新渲染状态
    if (_shouldUpdateRenderState()) {
      _updateVisibleBlocks();
    }

    notifyListeners();
  }

  /// 更新物理
  void _updatePhysics(double deltaTime) {
    final nearbyBlocks = chunkManager.getNearbyBlocks(
      player.position,
      Constants.renderDistance * 1.5,
    );
    player.update(deltaTime, nearbyBlocks);
  }

  /// 检查是否需要更新渲染状态
  bool _shouldUpdateRenderState() {
    final currentState = GameState(
      playerPosition: player.position,
      playerOrientation: player.orientation,
      visibleBlocks: _visibleBlocks,
    );

    final shouldUpdate =
        !_lastState.playerPosition.equals(player.position, 0.5) ||
        !_lastState.playerOrientation.equals(player.orientation, 0.05);

    _lastState = currentState;
    return shouldUpdate;
  }

  /// 更新可见方块
  void _updateVisibleBlocks() {
    chunkManager.getChunksAroundPlayer(player.position);

    _visibleBlocks =
        chunkManager
            .getNearbyBlocks(player.position)
            .where((block) => !block.penetrable && _isBlockInView(block))
            .toList()
          ..sort((a, b) => _getBlockDepth(b).compareTo(_getBlockDepth(a)));
  }

  /// 检查方块是否在视锥体内
  bool _isBlockInView(Block block) {
    final relativePos = block.position - player.position;
    final rotatedPos = _rotateToViewSpace(relativePos);
    return rotatedPos.z > Constants.nearClip;
  }

  /// 获取方块深度
  double _getBlockDepth(Block block) {
    return (block.position - player.position).magnitude;
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

  @override
  void dispose() {
    _ticker.stop();
    controlManager.dispose();
    super.dispose();
  }

  // 公开属性
  List<Block> get visibleBlocks => _visibleBlocks;
  FocusNode get focusNode => controlManager.focusNode;
  bool get isMoving => controlManager.isMoving;
}
