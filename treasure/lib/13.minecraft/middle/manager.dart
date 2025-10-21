import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../base/block.dart';
import '../base/constant.dart';
import '../base/player.dart';
import '../base/vector.dart';
import 'chunk_manager.dart';
import 'control_manager.dart';

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
  late double _deltaTime;

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
    player = Player(position: Vector3(0, 20, 5));
    controlManager = ControlManager(player);
    chunkManager = ChunkManager();

    _updateVisibleBlocks();
    _startGameLoop();
  }

  /// 开始游戏循环
  void _startGameLoop() {
    _lastTime = 0;
    _deltaTime = 0;
    _ticker = createTicker(_update);
    _ticker.start();
  }

  /// 游戏更新
  void _update(Duration elapsed) {
    final currentTime = elapsed.inMilliseconds / 1000.0;
    _deltaTime = currentTime - _lastTime;
    _lastTime = currentTime;

    final double deltaTime = _deltaTime.clamp(
      Constants.minDeltaTime,
      Constants.maxDeltaTime,
    );

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
    final nearbyBlocks = chunkManager.getNearbyBlocks(player.position);
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
        !_lastState.playerPosition.equals(player.position) ||
        !_lastState.playerOrientation.equals(player.orientation);

    _lastState = currentState;
    return shouldUpdate;
  }

  /// 更新可见方块
  void _updateVisibleBlocks() {
    chunkManager.getChunksAroundPlayer(player.position);

    _visibleBlocks = chunkManager.getNearbyBlocks(
      player.position,
      Constants.renderDistance,
    );
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
  String get debugInfo =>
      'FPS: ${(1 / _deltaTime.clamp(0.001, 1000)).toStringAsFixed(0)}';
}
