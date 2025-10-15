// manager.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'base.dart';
import 'constant.dart';

/// 区块类
class Chunk {
  final int chunkX, chunkZ;
  final List<Block> blocks;
  final AABB bounds;
  bool isLoaded = false;

  Chunk(this.chunkX, this.chunkZ, this.blocks)
    : bounds = _calculateChunkBounds(chunkX, chunkZ);

  static AABB _calculateChunkBounds(int chunkX, int chunkZ) {
    final minX = chunkX * ChunkManager.chunkSize.toDouble();
    final minZ = chunkZ * ChunkManager.chunkSize.toDouble();
    final maxX = minX + ChunkManager.chunkSize.toDouble();
    final maxZ = minZ + ChunkManager.chunkSize.toDouble();

    return AABB(Vector3(minX, -64.0, minZ), Vector3(maxX, 256.0, maxZ));
  }
}

/// 区块管理器
class ChunkManager {
  static const int chunkSize = 16;
  static const int renderDistance = 4;

  final Map<String, Chunk> _loadedChunks = {};
  final WorldGenerator worldGenerator;

  ChunkManager(this.worldGenerator);

  /// 获取玩家周围的区块
  List<Chunk> getChunksAroundPlayer(Vector3 playerPos) {
    final playerChunkX = (playerPos.x / chunkSize).floor();
    final playerChunkZ = (playerPos.z / chunkSize).floor();

    final chunks = <Chunk>[];

    for (int x = -renderDistance; x <= renderDistance; x++) {
      for (int z = -renderDistance; z <= renderDistance; z++) {
        final chunkX = playerChunkX + x;
        final chunkZ = playerChunkZ + z;

        final chunk = _getOrCreateChunk(chunkX, chunkZ);
        if (chunk != null) {
          chunks.add(chunk);
        }
      }
    }

    _unloadDistantChunks(playerChunkX, playerChunkZ);

    return chunks;
  }

  Chunk? _getOrCreateChunk(int chunkX, int chunkZ) {
    final key = '$chunkX,$chunkZ';

    if (_loadedChunks.containsKey(key)) {
      return _loadedChunks[key];
    }

    final blocks = worldGenerator.generateChunk(chunkX, chunkZ);
    final chunk = Chunk(chunkX, chunkZ, blocks);
    _loadedChunks[key] = chunk;

    return chunk;
  }

  void _unloadDistantChunks(int centerX, int centerZ) {
    final keysToRemove = <String>[];

    _loadedChunks.forEach((key, chunk) {
      final distanceX = (chunk.chunkX - centerX).abs();
      final distanceZ = (chunk.chunkZ - centerZ).abs();

      if (distanceX > renderDistance + 1 || distanceZ > renderDistance + 1) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _loadedChunks.remove(key);
    }
  }

  /// 获取玩家附近的所有方块
  List<Block> getAllBlocks() {
    final blocks = <Block>[];
    for (final chunk in _loadedChunks.values) {
      blocks.addAll(chunk.blocks);
    }
    return blocks;
  }

  /// 获取玩家附近的方块（优化版本）
  List<Block> getNearbyBlocks(
    Vector3 playerPos, [
    double radius = Constants.renderDistance,
  ]) {
    final nearbyBlocks = <Block>[];
    final playerChunkX = (playerPos.x / chunkSize).floor();
    final playerChunkZ = (playerPos.z / chunkSize).floor();

    for (int x = -1; x <= 1; x++) {
      for (int z = -1; z <= 1; z++) {
        final chunkX = playerChunkX + x;
        final chunkZ = playerChunkZ + z;
        final key = '$chunkX,$chunkZ';

        final chunk = _loadedChunks[key];
        if (chunk != null) {
          for (final block in chunk.blocks) {
            if ((block.position - playerPos).magnitude <= radius) {
              nearbyBlocks.add(block);
            }
          }
        }
      }
    }

    return nearbyBlocks;
  }
}

/// 游戏管理器
class GameManager with ChangeNotifier implements TickerProvider {
  late final Ticker _ticker;
  late double _lastTime;

  late final Player player;
  late final List<Block> blocks;
  late final Octree octree;
  late final InputHandler inputHandler;
  late final WorldGenerator worldGenerator;
  late final ChunkManager chunkManager;

  Vector3 _lastPlayerPos = Vector3.zero;
  Vector3 _lastPlayerOrientation = Vector3.zero;
  List<Block> _visibleBlocks = [];

  // 性能优化：减少更新频率的计数器
  int _updateCounter = 0;
  static const int _visibleBlocksUpdateInterval = 3; // 每3帧更新一次可见方块

  GameManager() {
    _initialize();
  }

  /// 初始化游戏
  void _initialize() {
    worldGenerator = WorldGenerator();
    chunkManager = ChunkManager(worldGenerator);

    // 初始生成一些区块
    blocks = []; // 初始为空，通过chunkManager动态获取
    final worldBounds = worldGenerator.calculateWorldBounds();
    octree = Octree(worldBounds);

    player = Player(position: Vector3(0, 20, 5)); // 提高初始位置避免卡在地下
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

    // 获取当前玩家附近的方块用于碰撞检测
    final nearbyBlocks = chunkManager.getNearbyBlocks(
      player.position,
      Constants.renderDistance * 1.5,
    );
    player.update(deltaTime, nearbyBlocks);

    _updateCounter++;
    if (_updateCounter >= _visibleBlocksUpdateInterval) {
      _updateVisibleBlocks();
      _updateCounter = 0;
    }

    notifyListeners();
  }

  /// 更新可见方块
  void _updateVisibleBlocks() {
    // 检查玩家是否移动了足够远的距离
    final positionChanged = !_lastPlayerPos.equals(player.position, 0.5);
    final orientationChanged = !_lastPlayerOrientation.equals(
      player.orientation,
      0.05,
    );

    if (!positionChanged && !orientationChanged) {
      return;
    }

    _lastPlayerPos = player.position;
    _lastPlayerOrientation = player.orientation;

    // 更新区块（确保玩家周围的区块已加载）
    chunkManager.getChunksAroundPlayer(player.position);

    // 获取玩家附近的方块
    final nearbyBlocks = chunkManager.getNearbyBlocks(player.position);

    // 过滤可见方块
    _visibleBlocks = nearbyBlocks.where((block) {
      if (block.penetrable) return false;
      final relativePos = block.position - player.position;
      final rotatedPos = _rotateToViewSpace(relativePos);
      return rotatedPos.z > Constants.nearClip;
    }).toList();

    // 按距离排序（从远到近，用于正确渲染）
    _visibleBlocks.sort((a, b) {
      final distA = (a.position - player.position).magnitude;
      final distB = (b.position - player.position).magnitude;
      return distB.compareTo(distA);
    });

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

  /// 获取已加载区块数量（用于调试）
  int get loadedChunkCount =>
      chunkManager.getAllBlocks().length ~/
      (ChunkManager.chunkSize * ChunkManager.chunkSize);
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
  final Map<String, int> _chunkSeeds = {};

  /// 为区块生成种子
  int _getChunkSeed(int chunkX, int chunkZ) {
    final key = '$chunkX,$chunkZ';
    if (!_chunkSeeds.containsKey(key)) {
      _chunkSeeds[key] = _random.nextInt(0x7FFFFFFF);
    }
    return _chunkSeeds[key]!;
  }

  /// 生成单个区块
  List<Block> generateChunk(int chunkX, int chunkZ) {
    final blocks = <Block>[];
    final chunkSeed = _getChunkSeed(chunkX, chunkZ);
    final random = Random(chunkSeed);

    final baseX = chunkX * ChunkManager.chunkSize;
    final baseZ = chunkZ * ChunkManager.chunkSize;

    // 生成地形
    for (int x = 0; x < ChunkManager.chunkSize; x++) {
      for (int z = 0; z < ChunkManager.chunkSize; z++) {
        final worldX = baseX + x;
        final worldZ = baseZ + z;

        final height = _calculateHeight(worldX, worldZ, random);

        // 生成从基岩到地表的地形
        for (int y = -2; y <= height; y++) {
          BlockType type;
          if (y == height) {
            type = BlockType.grass;
          } else if (y >= height - 3) {
            type = BlockType.dirt;
          } else {
            type = BlockType.stone;
          }

          blocks.add(
            Block(
              Vector3(worldX.toDouble(), y.toDouble(), worldZ.toDouble()),
              type,
            ),
          );
        }

        // 偶尔生成树木
        if (random.nextDouble() < 0.02 && height > 0) {
          _generateTree(
            blocks,
            worldX.toDouble(),
            height + 1,
            worldZ.toDouble(),
            random,
          );
        }
      }
    }

    return blocks;
  }

  /// 计算地形高度（简化版噪声）
  int _calculateHeight(int x, int z, Random random) {
    final noise1 = _simpleNoise(x * 0.01, z * 0.01, random) * 8;
    final noise2 = _simpleNoise(x * 0.05, z * 0.05, random) * 4;
    final noise3 = _simpleNoise(x * 0.1, z * 0.1, random) * 2;

    final height = (noise1 + noise2 + noise3).round();
    return height.clamp(0, 20);
  }

  /// 简化的噪声函数
  double _simpleNoise(double x, double z, Random random) {
    final seed =
        (((x * 73856093).toInt()) ^ ((z * 19349663)).toInt()) & 0x7FFFFFFF;
    final localRandom = Random(seed);
    return localRandom.nextDouble() * 2 - 1;
  }

  /// 生成树木
  void _generateTree(
    List<Block> blocks,
    double x,
    int baseY,
    double z,
    Random random,
  ) {
    final trunkHeight = 3 + random.nextInt(2);

    // 树干
    for (int y = 0; y < trunkHeight; y++) {
      blocks.add(Block(Vector3(x, (baseY + y).toDouble(), z), BlockType.wood));
    }

    // 树冠
    final canopyStart = baseY + trunkHeight;
    for (int dx = -2; dx <= 2; dx++) {
      for (int dz = -2; dz <= 2; dz++) {
        for (int dy = 0; dy < 3; dy++) {
          if ((dx.abs() + dz.abs() + dy) <= 3) {
            blocks.add(
              Block(
                Vector3(x + dx, (canopyStart + dy).toDouble(), z + dz),
                BlockType.grass,
              ),
            );
          }
        }
      }
    }
  }

  /// 计算世界边界（无限地图）
  AABB calculateWorldBounds() {
    return AABB(
      Vector3(-double.infinity, -64.0, -double.infinity),
      Vector3(double.infinity, 256.0, double.infinity),
    );
  }

  // 保持向后兼容的方法
  List<Block> generateTerrain() {
    return generateChunk(0, 0);
  }

  AABB calculateWorldBoundsFromBlocks(List<Block> blocks) {
    return calculateWorldBounds();
  }
}
