import 'dart:math' as math;

import '../base/aabb.dart';
import '../base/block.dart';
import '../base/constant.dart';
import '../base/chunk.dart';
import '../base/vector.dart';

/// 预计算的树木数据
class PrecomputedTree {
  final Vector3Int coord; // 树干基部坐标
  final int trunkHeight; // 树干高度
  final AABBInt treeAABB; // 整棵树包围盒（包含树干和树冠）

  PrecomputedTree({
    required this.coord,
    required this.trunkHeight,
    required this.treeAABB,
  });
}

/// 世界生成器
class WorldGenerator {
  // 核心参数（与常量绑定）
  static const int _blockSize = Constants.blockSize;
  static const int _blockSizeHalf = Constants.blockSizeHalf;
  static const int _chunkBlockCount = Constants.chunkBlockCount;
  static const int _groupSize = Constants.chunkGroupSize;

  // 衍生尺寸
  static const int _chunkSize = _chunkBlockCount * _blockSize;
  static const int _groupTotalSize = _chunkSize * _groupSize;
  static const int _treeCanopyRadius = 2 * _blockSize;
  static const int _treeCanopyHeight = 4 * _blockSize;
  static const int _worldHeightMin = _blockSizeHalf;

  // 组级缓存
  final Map<Vector3Int, int> _groupSeeds = {};
  final Map<Vector3Int, List<List<int>>> _groupHeightMaps = {};
  final Map<Vector3Int, List<PrecomputedTree>> _groupPrecomputedTrees = {};
  final int index;

  WorldGenerator(this.index);

  // ---------------------- 坐标转换工具方法 ----------------------
  static Vector3Int _getGroupCoord(Vector3Int chunkCoord) => Vector3Int(
    chunkCoord.x ~/ _groupSize,
    chunkCoord.y ~/ _groupSize,
    chunkCoord.z ~/ _groupSize,
  );

  static Vector3Int _getGroupOffset(Vector3Int chunkCoord) => Vector3Int(
    chunkCoord.x % _groupSize,
    chunkCoord.y % _groupSize,
    chunkCoord.z % _groupSize,
  );

  // ---------------------- 种子与高度图生成 ----------------------
  int _getGroupSeed(Vector3Int groupCoord) {
    if (!_groupSeeds.containsKey(groupCoord)) {
      final baseSeed = math.Random(index).nextInt(0x7FFFFFFF);
      _groupSeeds[groupCoord] =
          (baseSeed ^ groupCoord.x ^ groupCoord.y ^ groupCoord.z) & 0x7FFFFFFF;
    }
    return _groupSeeds[groupCoord]!;
  }

  List<List<int>> _getGroupHeightMap(
    Vector3Int groupCoord,
    math.Random groupRandom,
  ) {
    if (_groupHeightMaps.containsKey(groupCoord)) {
      return _groupHeightMaps[groupCoord]!;
    }

    // 生成高度图
    final groupWorldX = groupCoord.x * _groupTotalSize;
    final groupWorldZ = groupCoord.z * _groupTotalSize;
    final groupHeightMap = List.generate(
      _groupTotalSize,
      (_) => List.filled(_groupTotalSize, 0),
    );
    for (int x = _blockSizeHalf; x < _groupTotalSize; x += _blockSize) {
      for (int z = _blockSizeHalf; z < _groupTotalSize; z += _blockSize) {
        final heightOffset = _calculateTerrainHeight(
          groupWorldX + x,
          groupWorldZ + z,
          groupRandom,
        );
        groupHeightMap[x][z] = _blockSizeHalf + heightOffset;
      }
    }

    // 预计算组内所有树木（使用整棵树的AABB）
    final groupTrees = <PrecomputedTree>[];
    for (int x = _blockSizeHalf; x < _groupTotalSize; x += _blockSize) {
      for (int z = _blockSizeHalf; z < _groupTotalSize; z += _blockSize) {
        final surfaceY = groupHeightMap[x][z];
        final blockWorldX = groupWorldX + x;
        final blockWorldZ = groupWorldZ + z;

        if (_shouldGenerateTree(surfaceY, groupRandom) &&
            _isAwayFromGroupEdge(
              blockWorldX,
              blockWorldZ,
              groupWorldX,
              groupWorldZ,
            )) {
          // 计算树干参数
          final trunkBaseY = _getSoilTopY(surfaceY);
          final trunkHeight =
              3 * _blockSize +
              groupRandom.nextInt(
                    ((4 * _blockSize - 3 * _blockSize) ~/ _blockSize) + 1,
                  ) *
                  _blockSize;

          // 计算整棵树的包围盒（包含树干和树冠）
          final treeMin = Vector3Int(
            blockWorldX - _treeCanopyRadius,
            trunkBaseY, // 从树干基部开始
            blockWorldZ - _treeCanopyRadius,
          );
          final treeMax = Vector3Int(
            blockWorldX + _treeCanopyRadius,
            trunkBaseY + trunkHeight + _treeCanopyHeight, // 到树冠顶部结束
            blockWorldZ + _treeCanopyRadius,
          );
          final treeAABB = AABBInt(treeMin, treeMax);

          // 存入组缓存
          groupTrees.add(
            PrecomputedTree(
              coord: Vector3Int(blockWorldX, trunkBaseY, blockWorldZ),
              trunkHeight: trunkHeight,
              treeAABB: treeAABB,
            ),
          );
        }
      }
    }

    _groupHeightMaps[groupCoord] = groupHeightMap;
    _groupPrecomputedTrees[groupCoord] = groupTrees;
    return groupHeightMap;
  }

  // ---------------------- 树木生成辅助方法 ----------------------
  bool _shouldGenerateTree(int surfaceY, math.Random groupRandom) =>
      surfaceY > 8 && groupRandom.nextDouble() < 0.2;

  bool _isAwayFromGroupEdge(
    int worldX,
    int worldZ,
    int groupWorldX,
    int groupWorldZ,
  ) {
    final groupInnerX = worldX - groupWorldX;
    final groupInnerZ = worldZ - groupWorldZ;
    return groupInnerX >= _treeCanopyRadius &&
        groupInnerX <= _groupTotalSize - _treeCanopyRadius &&
        groupInnerZ >= _treeCanopyRadius &&
        groupInnerZ <= _groupTotalSize - _treeCanopyRadius;
  }

  int _getSoilTopY(int surfaceY) {
    final soilYOffset = (surfaceY - _blockSizeHalf) % _blockSize;
    return surfaceY - soilYOffset;
  }

  // ---------------------- 地形高度与方块类型 ----------------------
  static BlockType _getBlockType(int worldY, int surfaceY) {
    if (worldY == surfaceY) return BlockType.grass;
    if (worldY >= surfaceY - 3 * _blockSize) return BlockType.dirt;
    return BlockType.stone;
  }

  static int _calculateTerrainHeight(
    int worldX,
    int worldZ,
    math.Random groupRandom,
  ) {
    final scale = 1.0 / _blockSize;
    final totalHeight =
        (_simpleNoise(
                      worldX * 0.01 * scale,
                      worldZ * 0.01 * scale,
                      groupRandom,
                    ) *
                    8 +
                _simpleNoise(
                      worldX * 0.05 * scale,
                      worldZ * 0.05 * scale,
                      groupRandom,
                    ) *
                    4 +
                _simpleNoise(
                      worldX * 0.1 * scale,
                      worldZ * 0.1 * scale,
                      groupRandom,
                    ) *
                    2)
            .round();
    return totalHeight.clamp(0, _groupTotalSize - _blockSizeHalf);
  }

  static double _simpleNoise(double x, double z, math.Random groupRandom) {
    final seed =
        (((x * 73856093).toInt()) ^ ((z * 19349663).toInt())) & 0x7FFFFFFF;
    return math.Random(seed ^ groupRandom.nextInt(0x7FFFFFFF)).nextDouble() *
            2 -
        1;
  }

  // ---------------------- 区块生成核心逻辑 ----------------------
  void generateChunk(Chunk chunk) {
    final chunkCoord = chunk.chunkCoord;
    final groupCoord = _getGroupCoord(chunkCoord);
    final groupRandom = math.Random(_getGroupSeed(groupCoord));
    final groupHeightMap = _getGroupHeightMap(groupCoord, groupRandom);
    final groupTrees = _groupPrecomputedTrees[groupCoord] ?? [];

    // 1. 生成地面方块
    final groupOffset = _getGroupOffset(chunkCoord);
    final chunkXStart = groupOffset.x * _chunkSize;
    final chunkZStart = groupOffset.z * _chunkSize;
    final worldXBase = chunkCoord.x * _chunkSize;
    final worldZBase = chunkCoord.z * _chunkSize;

    for (int x = _blockSizeHalf; x < _chunkSize; x += _blockSize) {
      for (int z = _blockSizeHalf; z < _chunkSize; z += _blockSize) {
        final surfaceY = groupHeightMap[chunkXStart + x][chunkZStart + z];
        for (
          int worldY = _worldHeightMin;
          worldY <= surfaceY;
          worldY += _blockSize
        ) {
          chunk.addBlock(
            Block(
              position: Vector3Int(worldXBase + x, worldY, worldZBase + z),
              type: _getBlockType(worldY, surfaceY),
            ),
          );
        }
      }
    }

    // 2. 生成树木（使用整棵树的AABB检测重叠）
    // 创建当前区块的包围盒
    final chunkMin = Vector3Int(
      chunkCoord.x * _chunkSize,
      chunkCoord.y * _chunkSize,
      chunkCoord.z * _chunkSize,
    );
    final chunkMax = Vector3Int(
      (chunkCoord.x + 1) * _chunkSize,
      (chunkCoord.y + 1) * _chunkSize,
      (chunkCoord.z + 1) * _chunkSize,
    );
    final chunkAABB = AABBInt(chunkMin, chunkMax);

    // 遍历组内树木，检测重叠并生成
    for (final tree in groupTrees) {
      if (tree.treeAABB.intersects(chunkAABB)) {
        _generateOverlappedTreePart(chunk, tree, chunkAABB, groupRandom);
      }
    }
  }

  // ---------------------- 生成重叠部分的树木 ----------------------
  void _generateOverlappedTreePart(
    Chunk chunk,
    PrecomputedTree tree,
    AABBInt chunkAABB,
    math.Random groupRandom,
  ) {
    final trunkX = tree.coord.x;
    final trunkZ = tree.coord.z;
    final trunkBaseY = tree.coord.y;
    final trunkHeight = tree.trunkHeight;

    // 1. 生成当前区块内的树干
    for (int yOffset = 0; yOffset < trunkHeight; yOffset += _blockSize) {
      final trunkPos = Vector3Int(trunkX, trunkBaseY + yOffset, trunkZ);
      if (chunkAABB.contains(trunkPos)) {
        chunk.addBlock(Block(position: trunkPos, type: BlockType.wood));
      }
    }

    // 2. 生成当前区块内的树叶
    final canopyBaseY = trunkBaseY + trunkHeight; // 树冠基部Y坐标

    for (
      int xOffset = -_treeCanopyRadius;
      xOffset <= _treeCanopyRadius;
      xOffset += _blockSize
    ) {
      for (
        int zOffset = -_treeCanopyRadius;
        zOffset <= _treeCanopyRadius;
        zOffset += _blockSize
      ) {
        for (
          int yOffset = 0;
          yOffset < _treeCanopyHeight;
          yOffset += _blockSize
        ) {
          final leafPos = Vector3Int(
            trunkX + xOffset,
            canopyBaseY + yOffset,
            trunkZ + zOffset,
          );

          // 仅生成区块内的树叶
          if (chunkAABB.contains(leafPos)) {
            // 计算2D平面距离
            final distance2D = math.sqrt(
              (xOffset * xOffset + zOffset * zOffset).toDouble(),
            );

            // 根据高度调整最大距离（顶部较小，底部较大）
            final heightFactor = 1.0 - (yOffset / _treeCanopyHeight);
            final maxDistance = _treeCanopyRadius * (0.3 + 0.7 * heightFactor);

            // 简单的球形检测
            final distance3D = math.sqrt(
              distance2D * distance2D +
                  (yOffset - _treeCanopyHeight / 2) *
                      (yOffset - _treeCanopyHeight / 2) /
                      4.0,
            );

            if (distance3D <= maxDistance) {
              chunk.addBlock(Block(position: leafPos, type: BlockType.leaf));
            }
          }
        }
      }
    }
  }
}
