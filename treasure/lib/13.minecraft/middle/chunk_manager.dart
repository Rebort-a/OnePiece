import 'dart:collection';
import 'dart:math' as math;

import '../base/block.dart';
import '../base/chunk.dart';
import '../base/constant.dart';
import '../base/vector.dart';
import 'world_generator.dart';

/// 区块管理器 - 添加加载优化
class ChunkManager {
  static const int distance = Constants.renderChunkDistance;
  static const int distanceSquare = distance * distance;

  final Map<Vector3Int, Chunk> _loadedChunks = HashMap();
  final Queue<Vector3Int> _chunkLoadQueue = Queue();
  late final WorldGenerator _worldGenerator;

  // 性能优化
  Vector3Int _lastPlayerChunk = Vector3Int.zero;
  int _framesSinceLastUpdate = 0;

  ChunkManager() {
    _worldGenerator = WorldGenerator(math.Random().nextInt(1000));
  }

  static Vector3Int getChunkCoord(Vector3 worldPos) {
    return Vector3Int(
      (worldPos.x / Constants.chunkSize).floor(),
      (worldPos.y / Constants.chunkSize).floor(),
      (worldPos.z / Constants.chunkSize).floor(),
    );
  }

  /// 优化区块更新频率
  void updateChunks(Vector3 playerPos) {
    final playerChunk = getChunkCoord(playerPos);

    // 每4帧检查一次区块更新，减少CPU开销
    _framesSinceLastUpdate++;
    if (_framesSinceLastUpdate < 4 &&
        (playerChunk - _lastPlayerChunk).magnitudeSquare < 4) {
      return;
    }

    _framesSinceLastUpdate = 0;
    _lastPlayerChunk = playerChunk;

    _unloadDistantChunks(playerChunk);
    _loadChunksAroundPlayer(playerChunk);
  }

  /// 卸载远处区块
  void _unloadDistantChunks(Vector3Int playerChunk) {
    final chunksToRemove = <Vector3Int>[];
    for (final chunkCoord in _loadedChunks.keys) {
      final dx = (chunkCoord.x - playerChunk.x).abs();
      final dz = (chunkCoord.z - playerChunk.z).abs();

      if (dx > distance || dz > distance) {
        chunksToRemove.add(chunkCoord);
      }
    }
    for (final coord in chunksToRemove) {
      _loadedChunks.remove(coord);
    }
  }

  /// 加载周围区块（优化加载顺序）
  void _loadChunksAroundPlayer(Vector3Int playerChunk) {
    // 优先加载玩家前方的区块
    final loadOrder = _getChunkLoadOrder(playerChunk);

    for (final chunkCoord in loadOrder) {
      if (!_loadedChunks.containsKey(chunkCoord) &&
          !_chunkLoadQueue.contains(chunkCoord)) {
        _scheduleChunkLoad(chunkCoord);
      }
    }
  }

  /// 获取区块加载顺序（玩家前方优先）
  List<Vector3Int> _getChunkLoadOrder(Vector3Int playerChunk) {
    final chunks = <Vector3Int>[];

    // 按距离和方向排序
    for (int x = -distance; x <= distance; x++) {
      for (int z = -distance; z <= distance; z++) {
        for (int y = -distance; y <= distance; y++) {
          final chunkCoord = Vector3Int(
            playerChunk.x + x,
            playerChunk.y + y,
            playerChunk.z + z,
          );

          // 计算到玩家的距离（用于排序）
          final distanceSq = (chunkCoord - playerChunk).magnitudeSquare;
          if (distanceSq <= distanceSquare) {
            chunks.add(chunkCoord);
          }
        }
      }
    }

    // 按距离排序，近的优先
    chunks.sort((a, b) {
      final distA = (a - playerChunk).magnitudeSquare;
      final distB = (b - playerChunk).magnitudeSquare;
      return distA.compareTo(distB);
    });

    return chunks;
  }

  /// 调度区块加载
  void _scheduleChunkLoad(Vector3Int chunkCoord) {
    if (!_chunkLoadQueue.contains(chunkCoord)) {
      _chunkLoadQueue.addLast(chunkCoord);
    }
  }

  /// 处理加载队列（每帧限制数量）
  void processLoadQueue() {
    // 每帧最多加载1个区块，避免卡顿
    if (_chunkLoadQueue.isNotEmpty) {
      final chunkCoord = _chunkLoadQueue.removeFirst();
      _loadChunk(chunkCoord);
    }
  }

  /// 检查是否有待加载区块
  bool get hasPendingChunks => _chunkLoadQueue.isNotEmpty;

  /// 加载单个区块
  void _loadChunk(Vector3Int chunkCoord) {
    if (!_loadedChunks.containsKey(chunkCoord)) {
      final chunk = Chunk(chunkCoord);
      _worldGenerator.generateChunk(chunk);
      _loadedChunks[chunkCoord] = chunk;
    }
  }

  /// 获取渲染范围内的区块
  List<Chunk> getChunksInRenderRange(Vector3 playerPos) {
    final playerChunk = getChunkCoord(playerPos);
    final chunks = <Chunk>[];

    for (final chunk in _loadedChunks.values) {
      if ((chunk.chunkCoord - playerChunk).magnitudeSquare <= distanceSquare) {
        chunks.add(chunk);
      }
    }
    return chunks;
  }

  /// 获取玩家附近方块
  List<Block> getBlocksNearPlayer(Vector3 playerPos, double radius) {
    final chunks = getChunksInRenderRange(playerPos);

    final min = Vector3(
      playerPos.x - radius,
      playerPos.y - radius,
      playerPos.z - radius,
    );
    final max = Vector3(
      playerPos.x + radius,
      playerPos.y + radius,
      playerPos.z + radius,
    );

    final List<Block> blocks = [];
    for (final chunk in chunks) {
      final chunkBlocks = chunk.octree.queryRange(min, max);
      blocks.addAll(chunkBlocks);
    }

    return blocks;
  }
}
