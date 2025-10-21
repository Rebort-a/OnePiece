import '../base/block.dart';
import '../base/chunk.dart';
import '../base/constant.dart';
import '../base/vector.dart';
import 'world_generator.dart';

/// 区块管理器
class ChunkManager {
  static const int chunkSize = 16;
  static const int renderDistance = 4;

  final Map<String, Chunk> _loadedChunks = {};
  final WorldGenerator _worldGenerator = WorldGenerator();

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

    // 生成区块方块
    final blocks = _worldGenerator.generateChunk(chunkX, chunkZ);
    // 创建区块（使用Vector3Int作为坐标）
    final chunkCoord = Vector3Int(chunkX, 0, chunkZ); // Y轴固定为0层（无垂直区块划分）
    final chunk = Chunk(chunkCoord);

    // 将生成的方块添加到区块的八叉树中
    for (final block in blocks) {
      chunk.addBlock(block);
    }

    _loadedChunks[key] = chunk;
    return chunk;
  }

  void _unloadDistantChunks(int centerX, int centerZ) {
    final keysToRemove = <String>[];

    _loadedChunks.forEach((key, chunk) {
      final distanceX = (chunk.chunkCoord.x - centerX).abs();
      final distanceZ = (chunk.chunkCoord.z - centerZ).abs();

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
      blocks.addAll(chunk.getAllBlocksInChunk());
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
          // 从八叉树查询区块内的方块
          for (final block in chunk.getAllBlocksInChunk()) {
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
