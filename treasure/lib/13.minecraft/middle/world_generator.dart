import 'dart:math' as math;

import '../base/block.dart';
import '../base/constant.dart';
import '../base/chunk.dart';
import '../base/vector.dart';

/// 世界生成器
class WorldGenerator {
  static const int chunkSize = Constants.chunkBlockCount * Constants.blockSize;

  final Map<Vector3Int, int> _chunkSeeds = {};
  final int index;

  WorldGenerator(this.index);

  /// 生成区块种子
  int _getChunkSeed(Chunk chunk) {
    final chunkCoord = chunk.chunkCoord;

    if (!_chunkSeeds.containsKey(chunkCoord)) {
      final baseSeed = math.Random(index).nextInt(0x7FFFFFFF);
      _chunkSeeds[chunkCoord] =
          (baseSeed ^ chunkCoord.x ^ chunkCoord.y ^ chunkCoord.z) & 0x7FFFFFFF;
    }
    return _chunkSeeds[chunkCoord]!;
  }

  /// 生成区块
  void generateChunk(Chunk chunk) {
    final chunkSeed = _getChunkSeed(chunk);
    final random = math.Random(chunkSeed);

    final blockSize = Constants.blockSize;
    final blockSizeHalf = Constants.blockSizeHalf;

    final worldHeightMin = blockSizeHalf;

    final worldXBase = chunk.chunkCoord.x * chunkSize;
    final worldZBase = chunk.chunkCoord.z * chunkSize;

    // 生成高度图
    final heightMap = _generateHeightMap(worldXBase, worldZBase, chunkSize);

    // 生成方块
    for (int x = blockSizeHalf; x < chunkSize; x += blockSize) {
      for (int z = blockSizeHalf; z < chunkSize; z += blockSize) {
        final worldX = worldXBase + x;
        final worldZ = worldZBase + z;
        final surfaceY = heightMap[x][z];

        // 从底部到地表生成方块
        for (
          int worldY = worldHeightMin;
          worldY <= surfaceY;
          worldY += blockSize
        ) {
          final blockType = _getBlockType(worldY, surfaceY);
          chunk.addBlock(
            Block(
              position: Vector3Int(worldX, worldY, worldZ),
              type: blockType,
            ),
          );
        }

        if (random.nextDouble() < 0.1 && surfaceY > 10) {
          _generateTree(chunk, worldX, surfaceY, worldZ, random);
        }
      }
    }
  }

  /// 获取方块类型
  BlockType _getBlockType(int worldY, int surfaceY) {
    if (worldY == surfaceY) return BlockType.grass;
    if (worldY >= surfaceY - 3 * Constants.blockSize) return BlockType.dirt;
    return BlockType.stone;
  }

  /// 生成高度图
  List<List<int>> _generateHeightMap(
    int worldXBase,
    int worldZBase,
    int chunkSize,
  ) {
    return List.generate(chunkSize, (x) {
      return List.generate(chunkSize, (z) {
        final worldX = worldXBase + x;
        final worldZ = worldZBase + z;
        final heightOffset = _calculateTerrainHeight(worldX, worldZ);
        return Constants.blockSizeHalf + heightOffset;
      });
    });
  }

  /// 简化噪声计算：综合多尺度噪声计算地形高度
  int _calculateTerrainHeight(int worldX, int worldZ) {
    // 大尺度地形噪声：缩放系数0.01，影响程度（振幅）8
    final noise1 =
        _simpleNoise(
          worldX * 0.01, // 地形噪声缩放系数1（大尺度地形）
          worldZ * 0.01, // 地形噪声缩放系数1（大尺度地形）
        ) *
        8; // 地形噪声振幅1（大尺度地形影响程度）

    // 中尺度地形噪声：缩放系数0.05，影响程度（振幅）4
    final noise2 =
        _simpleNoise(
          worldX * 0.05, // 地形噪声缩放系数2（中尺度地形）
          worldZ * 0.05, // 地形噪声缩放系数2（中尺度地形）
        ) *
        4; // 地形噪声振幅2（中尺度地形影响程度）

    // 小尺度细节噪声：缩放系数0.1，影响程度（振幅）2
    final noise3 =
        _simpleNoise(
          worldX * 0.1, // 地形噪声缩放系数3（小尺度细节）
          worldZ * 0.1, // 地形噪声缩放系数3（小尺度细节）
        ) *
        2; // 地形噪声振幅3（小尺度细节影响程度）

    final totalHeight = (noise1 + noise2 + noise3).round();
    return totalHeight.clamp(0, 20 - Constants.blockSizeHalf);
  }

  /// 轻量噪声函数：生成 [-1, 1) 范围的噪声值
  static double _simpleNoise(double x, double z) {
    // 简化哈希计算，使用指定的哈希乘数生成种子
    final seed =
        ((x * 73856093).toInt() ^ // 噪声哈希乘数1（用于噪声函数）
            (z * 19349663).toInt()) & // 噪声哈希乘数2（用于噪声函数）
        0x7FFFFFFF; // 最大随机种子值
    final random = math.Random(seed);
    return random.nextDouble() * 2 - 1;
  }

  /// 生成树木：包含树干和树冠
  static void _generateTree(
    Chunk chunk,
    int x,
    int baseY,
    int z,
    math.Random random,
  ) {
    final blockSize = Constants.blockSize;
    // 树干高度范围：最小3个方块高度，最大4个方块高度（按方块尺寸换算）
    final minTrunkHeight = 3 * blockSize; // 树干最小高度（单位：方块数）
    final maxTrunkHeight = 4 * blockSize; // 树干最大高度（单位：方块数）

    final trunkHeight =
        minTrunkHeight +
        random.nextInt((maxTrunkHeight - minTrunkHeight) ~/ blockSize + 1) *
            blockSize;

    // 生成树干（木材方块）
    for (int yOffset = 0; yOffset < trunkHeight; yOffset += blockSize) {
      chunk.addBlock(
        Block(
          position: Vector3Int(x, (baseY + yOffset), z),
          type: BlockType.wood,
        ),
      );
    }

    // 生成树冠（树叶方块）
    final canopyStartY = baseY + trunkHeight;
    // 树冠半径：2个方块（按方块尺寸换算）
    final treeCanopyRadius = 2 * blockSize; // 树冠半径（单位：方块数）

    // 遍历树冠范围内的方块位置
    for (
      int xOffset = -treeCanopyRadius;
      xOffset <= treeCanopyRadius;
      xOffset += blockSize
    ) {
      for (
        int zOffset = -treeCanopyRadius;
        zOffset <= treeCanopyRadius;
        zOffset += blockSize
      ) {
        // 树冠高度：4个方块
        for (int yOffset = 0; yOffset < 4 * blockSize; yOffset += blockSize) {
          // 计算3D距离
          final distanceXZ = (xOffset * xOffset + zOffset * zOffset).toDouble();
          final distance3D = math.sqrt(
            distanceXZ + (yOffset * yOffset).toDouble(),
          );

          // 树冠形状：底部较大，向上逐渐变小
          final maxDistance =
              treeCanopyRadius * (1.0 - yOffset / (4.0 * blockSize)) +
              blockSize;

          if (distance3D <= maxDistance) {
            chunk.addBlock(
              Block(
                position: Vector3Int(
                  x + xOffset,
                  (canopyStartY + yOffset),
                  z + zOffset,
                ),
                type: BlockType.leaf,
              ),
            );
          }
        }
      }
    }
  }
}
