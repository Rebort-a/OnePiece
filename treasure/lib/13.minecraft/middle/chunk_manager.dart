import 'dart:collection';

import '../base/aabb.dart';
import '../base/block.dart';
import '../base/chunk.dart';
import '../base/constant.dart';
import '../base/vector.dart';
import 'world_generator.dart';

/// 区块管理器
class ChunkManager {
  static const int chunkSize = Constants.chunkBlockCount * Constants.blockSize;
  static const int distance = Constants.loadChunkCount;
  static const int distanceSquare = distance * distance;

  final Map<Vector3Int, Chunk> _archivedBlocks = HashMap();
  final Map<Vector3Int, Chunk> _loadedChunks = HashMap();
  final Queue<Vector3Int> _chunkLoadQueue = Queue();
  late final WorldGenerator _worldGenerator;

  // 性能优化
  Vector3Int _lastPlayerChunk = Vector3Int.zero;

  ChunkManager() {
    _worldGenerator = WorldGenerator(0);
  }

  static Vector3Int getChunkCoord(Vector3 worldPos) {
    return Vector3Int(
      worldPos.x ~/ chunkSize,
      worldPos.y ~/ chunkSize,
      worldPos.z ~/ chunkSize,
    );
  }

  /// 区块更新
  void updateChunks(Vector3 playerPos) {
    final playerChunk = getChunkCoord(playerPos);

    if (playerChunk == _lastPlayerChunk) {
      return;
    }

    _lastPlayerChunk = playerChunk;

    // 1.生成需要保留的区块列表
    final aroundChunks = _getAroundChunks(playerChunk);

    // 2. 卸载不在需要保留列表中的区块
    final chunksToUnload = _loadedChunks.keys
        .where((coord) => !aroundChunks.contains(coord))
        .toList();
    for (final coord in chunksToUnload) {
      _loadedChunks.remove(coord);
    }

    // 3. 加载需要但未加载的区块
    for (final chunkCoord in aroundChunks) {
      if (!_loadedChunks.containsKey(chunkCoord) &&
          !_chunkLoadQueue.contains(chunkCoord)) {
        _chunkLoadQueue.addLast(chunkCoord);
      }
    }
  }

  /// 获取玩家周围区块
  Set<Vector3Int> _getAroundChunks(Vector3Int playerChunk) {
    final Set<Vector3Int> chunks = {};

    // 一次遍历生成所有在距离范围内的区块
    for (int x = -distance; x <= distance; x++) {
      for (int z = -distance; z <= distance; z++) {
        for (int y = -distance; y <= distance; y++) {
          final chunkCoord = Vector3Int(
            playerChunk.x + x,
            playerChunk.y + y,
            playerChunk.z + z,
          );

          chunks.add(chunkCoord);
        }
      }
    }

    return chunks;
  }

  /// 处理加载队列
  void processLoadQueue() {
    // 每次最多加载1个区块，避免卡顿
    if (_chunkLoadQueue.isNotEmpty) {
      final chunkCoord = _chunkLoadQueue.removeFirst();
      _loadChunk(chunkCoord);
    }
  }

  /// 加载单个区块
  void _loadChunk(Vector3Int chunkCoord) {
    if (!_loadedChunks.containsKey(chunkCoord)) {
      if (_archivedBlocks.containsKey(chunkCoord)) {
        _loadedChunks[chunkCoord] = _archivedBlocks[chunkCoord]!;
      } else {
        final chunk = Chunk(chunkCoord);
        _worldGenerator.generateChunk(chunk);
        _archivedBlocks[chunkCoord] = chunk;
        _loadedChunks[chunkCoord] = chunk;
      }
    }
  }

  /// 获取玩家附近方块
  List<Block> getBlocksNearPlayer(Vector3 playerPos, double radius) {
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
    for (final chunk in _loadedChunks.values) {
      final chunkBlocks = chunk.octree.queryRange(AABB(min, max));
      blocks.addAll(chunkBlocks);
    }

    return blocks;
  }

  /// 检查是否有待加载区块
  bool get hasPendingChunks => _chunkLoadQueue.isNotEmpty;
}
