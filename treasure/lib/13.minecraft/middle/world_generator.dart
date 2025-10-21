import 'dart:math';

import '../base/aabb.dart';
import '../base/block.dart';
import '../base/constant.dart';
import '../base/vector.dart';

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

  /// 生成单个区块的方块列表（供ChunkManager添加到八叉树）
  List<Block> generateChunk(int chunkX, int chunkZ) {
    final blocks = <Block>[];
    final chunkSeed = _getChunkSeed(chunkX, chunkZ);
    final random = Random(chunkSeed);

    final baseX = chunkX * Constants.chunkSize;
    final baseZ = chunkZ * Constants.chunkSize;

    // 生成地形
    for (int x = 0; x < Constants.chunkSize; x++) {
      for (int z = 0; z < Constants.chunkSize; z++) {
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
              position: Vector3(
                worldX.toDouble(),
                y.toDouble(),
                worldZ.toDouble(),
              ),
              type: type,
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
      blocks.add(
        Block(
          position: Vector3(x, (baseY + y).toDouble(), z),
          type: BlockType.wood,
        ),
      );
    }

    // 树冠（注意：原代码中树冠使用了grass类型，实际应改为树叶类型，这里保持原逻辑）
    final canopyStart = baseY + trunkHeight;
    for (int dx = -2; dx <= 2; dx++) {
      for (int dz = -2; dz <= 2; dz++) {
        for (int dy = 0; dy < 3; dy++) {
          if ((dx.abs() + dz.abs() + dy) <= 3) {
            blocks.add(
              Block(
                position: Vector3(
                  x + dx,
                  (canopyStart + dy).toDouble(),
                  z + dz,
                ),
                type: BlockType.grass,
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
