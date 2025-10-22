import 'dart:collection';
import 'dart:math' as math;

import '../base/block.dart';
import '../base/chunk.dart';
import '../base/constant.dart';
import '../base/vector.dart';
import 'world_generator.dart';

/// 区块管理器
class ChunkManager {
  static const int distance = Constants.renderChunkDistance;
  static const int distanceSquare = distance * distance;

  final Map<Vector3Int, Chunk> _loadedChunks = HashMap();

  final Queue<Vector3Int> _chunkLoadQueue = Queue();

  late final WorldGenerator _worldGenerator;

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

  /// 更新区块加载
  void updateChunks(Vector3 playerPos) {
    final playerChunk = getChunkCoord(playerPos);
    _unloadDistantChunks(playerChunk);
    _loadChunksAroundPlayer(playerChunk);
  }

  /// 卸载远处区块
  void _unloadDistantChunks(Vector3Int playerChunk) {
    final chunksToRemove = <Vector3Int>[];
    for (final chunkCoord in _loadedChunks.keys) {
      // 分开计算轴方向的距离差
      final dx = (chunkCoord.x - playerChunk.x).abs();
      final dz = (chunkCoord.z - playerChunk.z).abs();

      // 只要有一个轴方向超出范围，就需要卸载
      if (dx > distance || dz > distance) {
        chunksToRemove.add(chunkCoord);
      }
    }
    for (final coord in chunksToRemove) {
      _loadedChunks.remove(coord);
    }
  }

  /// 加载周围区块
  void _loadChunksAroundPlayer(Vector3Int playerChunk) {
    for (int x = -distance; x <= distance; x++) {
      for (int z = -distance; z <= distance; z++) {
        for (int y = -distance; y <= distance; y++) {
          final chunkCoord = Vector3Int(
            playerChunk.x + x,
            playerChunk.y + y,
            playerChunk.z + z,
          );
          if (!_loadedChunks.containsKey(chunkCoord) &&
              !_chunkLoadQueue.contains(chunkCoord)) {
            _scheduleChunkLoad(chunkCoord);
          }
        }
      }
    }
  }

  /// 调度区块加载
  void _scheduleChunkLoad(Vector3Int chunkCoord) {
    if (!_chunkLoadQueue.contains(chunkCoord)) {
      _chunkLoadQueue.addLast(chunkCoord);
    }
  }

  /// 处理加载队列
  void processLoadQueue() {
    if (_chunkLoadQueue.isNotEmpty) {
      final chunkCoord = _chunkLoadQueue.removeFirst();
      _loadChunk(chunkCoord);
    }
  }

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

    return blocks.toList();
  }
}
