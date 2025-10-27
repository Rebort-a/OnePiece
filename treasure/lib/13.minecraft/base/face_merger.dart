import 'dart:collection';
import 'dart:math' as math;

import 'aabb.dart';
import 'block.dart';
import 'constant.dart';
import 'vector.dart';

/// 辅助类：2D矩形
class _Rectangle2D {
  final int minX, minY, maxX, maxY;

  _Rectangle2D(this.minX, this.minY, this.maxX, this.maxY);
}

/// 辅助类：元组
class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple(this.item1, this.item2);
}

/// 合并后的面
class MergedFace {
  final BlockType blockType;
  final Vector3Int normal;
  final Vector3Int min;
  final Vector3Int max;
  final List<Vector3Int> vertices;

  MergedFace({
    required this.blockType,
    required this.normal,
    required this.min,
    required this.max,
  }) : vertices = _calculateVertices(min, max, normal);

  static List<Vector3Int> _calculateVertices(
    Vector3Int min,
    Vector3Int max,
    Vector3Int normal,
  ) {
    // 根据法线方向计算面的四个顶点
    if (normal.x.abs() > 0.5) {
      // X方向的面
      final x = normal.x > 0 ? max.x : min.x;
      return [
        Vector3Int(x, min.y, min.z),
        Vector3Int(x, max.y, min.z),
        Vector3Int(x, max.y, max.z),
        Vector3Int(x, min.y, max.z),
      ];
    } else if (normal.y.abs() > 0.5) {
      // Y方向的面
      final y = normal.y > 0 ? max.y : min.y;
      return [
        Vector3Int(min.x, y, min.z),
        Vector3Int(max.x, y, min.z),
        Vector3Int(max.x, y, max.z),
        Vector3Int(min.x, y, max.z),
      ];
    } else {
      // Z方向的面
      final z = normal.z > 0 ? max.z : min.z;
      return [
        Vector3Int(min.x, min.y, z),
        Vector3Int(max.x, min.y, z),
        Vector3Int(max.x, max.y, z),
        Vector3Int(min.x, max.y, z),
      ];
    }
  }

  AABBInt get bounds => AABBInt(min, max);
}

/// 面合并器
class FaceMerger {
  /// 合并相邻的方块面
  static List<MergedFace> mergeFaces(
    List<Block> blocks,
    Vector3 cameraPosition,
  ) {
    final mergedFaces = <MergedFace>[];

    // 第一步：按法线+类型分组，但保留空间位置信息
    final faceGroups = <String, List<BlockFace>>{};

    for (final block in blocks) {
      final visibleFaces = block.getVisibleFaces(cameraPosition);

      for (final face in visibleFaces) {
        final normal = face.normal;
        final blockPos = block.position;

        // 改进的分组键：法线 + 类型 + 区块坐标（避免远距离合并）
        final chunkX = (blockPos.x / 4).floor(); // 每4个单位一个区块
        final chunkZ = (blockPos.z / 4).floor();

        final key =
            '${normal.x},${normal.y},${normal.z},'
            '${face.type.index},$chunkX,$chunkZ';

        if (!faceGroups.containsKey(key)) {
          faceGroups[key] = [];
        }
        faceGroups[key]!.add(face);
      }
    }

    // 第二步：对每个组进行保守合并
    for (final group in faceGroups.values) {
      if (group.isEmpty) continue;

      final normal = group.first.normal;
      final blockType = group.first.type;

      // 使用保守的合并策略
      final merged = _mergeFacesConservative(group, normal, blockType, blocks);
      mergedFaces.addAll(merged);
    }

    return mergedFaces;
  }

  /// 保守合并策略 - 只合并直接相邻的面
  static List<MergedFace> _mergeFacesConservative(
    List<BlockFace> faces,
    Vector3Int normal,
    BlockType blockType,
    List<Block> allBlocks,
  ) {
    if (faces.isEmpty) return [];

    final mergedFaces = <MergedFace>[];
    final processed = <BlockFace>{};

    for (final face in faces) {
      if (processed.contains(face)) continue;

      // 找到所有可以直接合并的相邻面
      final mergeGroup = _findMergeGroup(face, faces, normal, allBlocks);
      processed.addAll(mergeGroup);

      if (mergeGroup.length == 1) {
        // 单个面，不合并
        final bounds = _getFaceBounds3D(mergeGroup.first, normal);
        mergedFaces.add(
          MergedFace(
            blockType: blockType,
            normal: normal,
            min: bounds.item1,
            max: bounds.item2,
          ),
        );
      } else {
        // 合并相邻面
        final merged = _mergeFaceGroup(mergeGroup, normal, blockType);
        if (merged != null) {
          mergedFaces.add(merged);
        }
      }
    }

    return mergedFaces;
  }

  /// 查找可以合并的面组
  static List<BlockFace> _findMergeGroup(
    BlockFace startFace,
    List<BlockFace> allFaces,
    Vector3Int normal,
    List<Block> allBlocks,
  ) {
    final group = <BlockFace>[startFace];
    final queue = Queue<BlockFace>()..add(startFace);
    final visited = <BlockFace>{startFace};

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      // 查找直接相邻的面
      for (final neighbor in allFaces) {
        if (visited.contains(neighbor)) continue;

        if (_canMerge(current, neighbor, normal, allBlocks)) {
          visited.add(neighbor);
          group.add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    return group;
  }

  /// 判断两个面是否可以合并
  static bool _canMerge(
    BlockFace face1,
    BlockFace face2,
    Vector3Int normal,
    List<Block> allBlocks,
  ) {
    // 1. 检查是否在同一平面
    if (!_areFacesCoplanar(face1, face2, normal)) return false;

    // 2. 检查是否相邻
    if (!_areFacesAdjacent(face1, face2, normal)) return false;

    // 3. 检查合并后是否会被其他方块遮挡
    if (_wouldMergeBeOccluded(face1, face2, normal, allBlocks)) return false;

    return true;
  }

  /// 检查两个面是否在同一平面
  static bool _areFacesCoplanar(
    BlockFace face1,
    BlockFace face2,
    Vector3Int normal,
  ) {
    final planePos1 = _getPlaneCoordinate(face1.center, normal);
    final planePos2 = _getPlaneCoordinate(face2.center, normal);
    return (planePos1 - planePos2).abs() < Constants.epsilon;
  }

  /// 检查两个面是否相邻
  static bool _areFacesAdjacent(
    BlockFace face1,
    BlockFace face2,
    Vector3Int normal,
  ) {
    final bounds1 = _getFaceBounds(face1, normal);
    final bounds2 = _getFaceBounds(face2, normal);

    // 检查在U轴或V轴方向是否相邻
    final uAdjacent =
        (_approxEqual(bounds1.maxX, bounds2.minX) ||
            _approxEqual(bounds2.maxX, bounds1.minX)) &&
        (bounds1.minY < bounds2.maxY - Constants.epsilon &&
            bounds1.maxY > bounds2.minY + Constants.epsilon);

    final vAdjacent =
        (_approxEqual(bounds1.maxY, bounds2.minY) ||
            _approxEqual(bounds2.maxY, bounds1.minY)) &&
        (bounds1.minX < bounds2.maxX - Constants.epsilon &&
            bounds1.maxX > bounds2.minX + Constants.epsilon);

    return uAdjacent || vAdjacent;
  }

  /// 检查合并后的面是否会被遮挡
  static bool _wouldMergeBeOccluded(
    BlockFace face1,
    BlockFace face2,
    Vector3Int normal,
    List<Block> allBlocks,
  ) {
    // 计算合并后的边界
    final bounds1 = _getFaceBounds3D(face1, normal);
    final bounds2 = _getFaceBounds3D(face2, normal);

    final mergedMin = Vector3Int(
      math.min(bounds1.item1.x, bounds2.item1.x),
      math.min(bounds1.item1.y, bounds2.item1.y),
      math.min(bounds1.item1.z, bounds2.item1.z),
    );

    final mergedMax = Vector3Int(
      math.max(bounds1.item2.x, bounds2.item2.x),
      math.max(bounds1.item2.y, bounds2.item2.y),
      math.max(bounds1.item2.z, bounds2.item2.z),
    );

    // 检查合并区域是否有其他方块（可能造成遮挡）
    final mergedCenter = (mergedMin + mergedMax) ~/ 2;
    // 向法线方向偏移一点

    for (final block in allBlocks) {
      final blockPos = block.position;
      final blockMin = blockPos - Vector3Int.all(Constants.blockSizeHalf);
      final blockMax = blockPos + Vector3Int.all(Constants.blockSizeHalf);

      // 如果方块在合并面的后方且可能遮挡，则不能合并
      if (_isBehindPlane(blockPos, mergedCenter, normal) &&
          _aabbIntersects(blockMin, blockMax, mergedMin, mergedMax)) {
        return true;
      }
    }

    return false;
  }

  /// 合并面组
  static MergedFace? _mergeFaceGroup(
    List<BlockFace> faces,
    Vector3Int normal,
    BlockType blockType,
  ) {
    if (faces.isEmpty) return null;

    Vector3Int? minVec, maxVec;

    for (final face in faces) {
      final bounds = _getFaceBounds3D(face, normal);

      if (minVec == null || maxVec == null) {
        minVec = bounds.item1;
        maxVec = bounds.item2;
      } else {
        minVec = Vector3Int(
          math.min(minVec.x, bounds.item1.x),
          math.min(minVec.y, bounds.item1.y),
          math.min(minVec.z, bounds.item1.z),
        );
        maxVec = Vector3Int(
          math.max(maxVec.x, bounds.item2.x),
          math.max(maxVec.y, bounds.item2.y),
          math.max(maxVec.z, bounds.item2.z),
        );
      }
    }

    if (minVec == null || maxVec == null) return null;

    return MergedFace(
      blockType: blockType,
      normal: normal,
      min: minVec,
      max: maxVec,
    );
  }

  /// 获取面的2D边界（用于网格合并）
  static _Rectangle2D _getFaceBounds(BlockFace face, Vector3Int normal) {
    if (normal.x.abs() > 0.5) {
      // X方向的面，使用Y和Z坐标
      final yValues = face.vertices.map((v) => v.y).toList();
      final zValues = face.vertices.map((v) => v.z).toList();
      final minY = yValues.reduce(math.min);
      final maxY = yValues.reduce(math.max);
      final minZ = zValues.reduce(math.min);
      final maxZ = zValues.reduce(math.max);
      return _Rectangle2D(minY, minZ, maxY, maxZ);
    } else if (normal.y.abs() > 0.5) {
      // Y方向的面，使用X和Z坐标
      final xValues = face.vertices.map((v) => v.x).toList();
      final zValues = face.vertices.map((v) => v.z).toList();
      final minX = xValues.reduce(math.min);
      final maxX = xValues.reduce(math.max);
      final minZ = zValues.reduce(math.min);
      final maxZ = zValues.reduce(math.max);
      return _Rectangle2D(minX, minZ, maxX, maxZ);
    } else {
      // Z方向的面，使用X和Y坐标
      final xValues = face.vertices.map((v) => v.x).toList();
      final yValues = face.vertices.map((v) => v.y).toList();
      final minX = xValues.reduce(math.min);
      final maxX = xValues.reduce(math.max);
      final minY = yValues.reduce(math.min);
      final maxY = yValues.reduce(math.max);
      return _Rectangle2D(minX, minY, maxX, maxY);
    }
  }

  /// 获取面的3D边界
  static Tuple<Vector3Int, Vector3Int> _getFaceBounds3D(
    BlockFace face,
    Vector3Int normal,
  ) {
    final vertices = face.vertices;
    int minX = 0, minY = 0, minZ = 0, maxX = 0, maxY = 0, maxZ = 0;

    if (vertices.isNotEmpty) {
      minX = maxX = vertices[0].x;
      minY = maxY = vertices[0].y;
      minZ = maxZ = vertices[0].z;

      for (int i = 1; i < vertices.length; i++) {
        final vertex = vertices[i];
        minX = math.min(minX, vertex.x);
        maxX = math.max(maxX, vertex.x);
        minY = math.min(minY, vertex.y);
        maxY = math.max(maxY, vertex.y);
        minZ = math.min(minZ, vertex.z);
        maxZ = math.max(maxZ, vertex.z);
      }
    } else {
      minX = minY = minZ = 0;
      maxX = maxY = maxZ = 0;
    }
    // 根据法线方向调整边界，确保边界准确
    if (normal.x.abs() > 0.5) {
      final x = face.center.x;
      return Tuple(Vector3Int(x, minY, minZ), Vector3Int(x, maxY, maxZ));
    } else if (normal.y.abs() > 0.5) {
      final y = face.center.y;
      return Tuple(Vector3Int(minX, y, minZ), Vector3Int(maxX, y, maxZ));
    } else {
      final z = face.center.z;
      return Tuple(Vector3Int(minX, minY, z), Vector3Int(maxX, maxY, z));
    }
  }

  // 辅助方法
  static bool _isBehindPlane(
    Vector3Int point,
    Vector3Int planePoint,
    Vector3Int normal,
  ) {
    return (point - planePoint).dot(normal) < 0;
  }

  static bool _aabbIntersects(
    Vector3Int min1,
    Vector3Int max1,
    Vector3Int min2,
    Vector3Int max2,
  ) {
    return min1.x <= max2.x &&
        max1.x >= min2.x &&
        min1.y <= max2.y &&
        max1.y >= min2.y &&
        min1.z <= max2.z &&
        max1.z >= min2.z;
  }

  static int _getPlaneCoordinate(Vector3Int point, Vector3Int normal) {
    if (normal.x.abs() > 0) return point.x;
    if (normal.y.abs() > 0) return point.y;
    return point.z;
  }

  static bool _approxEqual(int a, int b) {
    return (a - b).abs() < 0;
  }
}
