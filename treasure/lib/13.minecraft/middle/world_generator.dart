import 'dart:math' as math;

import '../base/block.dart';
import '../base/constant.dart';
import '../base/chunk.dart';
import '../base/vector.dart';

/// 世界生成器
class WorldGenerator {
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
    final chunkSize = Constants.chunkSize;
    final worldHeightMin = Constants.worldHeightMin;

    final worldXBase = chunk.chunkCoord.x * chunkSize;
    final worldZBase = chunk.chunkCoord.z * chunkSize;

    // 生成高度图
    final heightMap = _generateHeightMap(worldXBase, worldZBase, chunkSize);

    // 生成方块
    for (int x = 0; x < chunkSize; x++) {
      for (int z = 0; z < chunkSize; z++) {
        final worldX = worldXBase + x;
        final worldZ = worldZBase + z;
        final surfaceY = heightMap[x][z];

        // 从底部到地表生成方块
        for (int worldY = worldHeightMin; worldY <= surfaceY; worldY++) {
          final blockType = _getBlockType(worldY, surfaceY);
          chunk.addBlock(
            Block(
              position: Vector3Int(worldX, worldY, worldZ),
              type: blockType,
            ),
          );
        }

        // 生成树木
        if (random.nextDouble() < Constants.treeProbability &&
            surfaceY > worldHeightMin) {
          _generateTree(chunk, worldX, surfaceY + 1, worldZ, random);
        }
      }
    }
  }

  /// 获取方块类型
  BlockType _getBlockType(int worldY, int surfaceY) {
    if (worldY == surfaceY) return BlockType.grass;
    if (worldY >= surfaceY - 3) return BlockType.dirt;
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
        return Constants.worldHeightMin + heightOffset;
      });
    });
  }

  /// 简化噪声计算
  int _calculateTerrainHeight(int worldX, int worldZ) {
    final noise1 = _simpleNoise(worldX * 0.01, worldZ * 0.01) * 8;
    final noise2 = _simpleNoise(worldX * 0.05, worldZ * 0.05) * 4;
    final noise3 = _simpleNoise(worldX * 0.1, worldZ * 0.1) * 2;

    final totalHeight = (noise1 + noise2 + noise3).round();
    return totalHeight.clamp(
      0,
      Constants.worldHeightMax - Constants.worldHeightMin,
    );
  }

  /// 轻量噪声函数
  static double _simpleNoise(double x, double z) {
    // 简化哈希计算，减少位运算
    final seed = ((x * 73856093).toInt() ^ (z * 19349663).toInt()) & 0x7FFFFFFF;
    final random = math.Random(seed);
    return random.nextDouble() * 2 - 1;
  }

  /// 生成树木
  static void _generateTree(
    Chunk chunk,
    int x,
    int baseY,
    int z,
    math.Random random,
  ) {
    final trunkHeight =
        Constants.minTrunkHeight +
        random.nextInt(Constants.maxTrunkHeight - Constants.minTrunkHeight + 1);

    // 树干
    for (int yOffset = 0; yOffset < trunkHeight; yOffset++) {
      chunk.addBlock(
        Block(
          position: Vector3Int(x, (baseY + yOffset), z),
          type: BlockType.wood,
        ),
      );
    }

    // 树冠
    final canopyStartY = baseY + trunkHeight;
    for (int xOffset = -2; xOffset <= 2; xOffset++) {
      for (int zOffset = -2; zOffset <= 2; zOffset++) {
        for (int yOffset = 0; yOffset < 3; yOffset++) {
          if ((xOffset.abs() + zOffset.abs() + yOffset) <= 3) {
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
