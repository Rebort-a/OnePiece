import 'block.dart';
import 'constant.dart';
import 'vector.dart';
import 'octree.dart';

/// 区块类
class Chunk {
  static const int chunkSize = Constants.chunkSize; // 区块边长（固定16）
  final Vector3Int chunkCoord; // 区块坐标（如(0,0,0)、(1,0,0)等）
  final BlockOctree octree; // 区块内的八叉树（范围与区块匹配）

  Chunk(this.chunkCoord)
    : octree = BlockOctree(
        worldSize: chunkSize,
        center: Vector3(
          chunkCoord.x * chunkSize + chunkSize / 2,
          chunkCoord.y * chunkSize + chunkSize / 2,
          chunkCoord.z * chunkSize + chunkSize / 2,
        ),
        maxBlocksPerNode: Constants.maxBlocksPerNode,
        minHalfSize: Constants.minHalfSize,
      );

  /// 添加方块到区块（直接操作八叉树，避免数据不一致）
  bool addBlock(Block block) {
    // 检查方块是否在当前区块范围内
    final worldMin = Vector3Int(
      chunkCoord.x * chunkSize,
      chunkCoord.y * chunkSize,
      chunkCoord.z * chunkSize,
    );
    final worldMax = worldMin + Vector3Int.all(chunkSize);
    final pos = block.position;
    if (pos.x < worldMin.x ||
        pos.x >= worldMax.x ||
        pos.y < worldMin.y ||
        pos.y >= worldMax.y ||
        pos.z < worldMin.z ||
        pos.z >= worldMax.z) {
      return false; // 方块不在当前区块范围内
    }
    return octree.insertBlock(block);
  }

  /// 从区块移除方块
  bool removeBlock(Block block) => octree.removeBlock(block);

  /// 获取区块内指定位置的方块
  Block? getBlock(Vector3Int position) => octree.getBlock(position);

  void removeBlockByPos(Vector3Int position) {
    Block? block = getBlock(position);
    if (block != null) {
      removeBlock(block);
    }
  }

  /// 获取整个区块内的所有方块
  List<Block> getAllBlocksInChunk() {
    final worldMin = Vector3Int(
      chunkCoord.x * chunkSize,
      chunkCoord.y * chunkSize,
      chunkCoord.z * chunkSize,
    );
    final worldMax = worldMin + Vector3Int.all(chunkSize);
    return octree.queryRange(worldMin.toVector3(), worldMax.toVector3());
  }

  /// 获取指定位置和半径内的方块
  List<Block> getBlocksInRange(Vector3 position, double radius) {
    final min = position - Vector3.all(radius);
    final max = position + Vector3.all(radius);
    return octree.queryRange(min, max);
  }
}
