// face_merger.dart
import 'dart:collection';
import 'dart:math' as math;

import 'aabb.dart';
import 'block.dart';
import 'constant.dart';
import 'vector.dart';

/// 合并后的面
class MergedFace {
  final BlockType blockType;
  final Vector3 normal;
  final Vector3 min;
  final Vector3 max;
  final List<Vector3> vertices;

  MergedFace({
    required this.blockType,
    required this.normal,
    required this.min,
    required this.max,
  }) : vertices = _calculateVertices(min, max, normal);

  static List<Vector3> _calculateVertices(
    Vector3 min,
    Vector3 max,
    Vector3 normal,
  ) {
    // 根据法线方向计算面的四个顶点
    if (normal.x.abs() > 0.5) {
      // X方向的面
      final x = normal.x > 0 ? max.x : min.x;
      return [
        Vector3(x, min.y, min.z),
        Vector3(x, max.y, min.z),
        Vector3(x, max.y, max.z),
        Vector3(x, min.y, max.z),
      ];
    } else if (normal.y.abs() > 0.5) {
      // Y方向的面
      final y = normal.y > 0 ? max.y : min.y;
      return [
        Vector3(min.x, y, min.z),
        Vector3(max.x, y, min.z),
        Vector3(max.x, y, max.z),
        Vector3(min.x, y, max.z),
      ];
    } else {
      // Z方向的面
      final z = normal.z > 0 ? max.z : min.z;
      return [
        Vector3(min.x, min.y, z),
        Vector3(max.x, min.y, z),
        Vector3(max.x, max.y, z),
        Vector3(min.x, max.y, z),
      ];
    }
  }

  AABB get bounds => AABB(min, max);

  @override
  String toString() {
    return 'MergedFace(type: $blockType, normal: $normal, min: $min, max: $max)';
  }
}

/// 面合并器 - 简化可靠版本
/// 面合并器 - 修复版本
class FaceMerger {
  static const double _epsilon = 0.001;

  /// 合并相邻的方块面 - 修复版本，避免过度合并
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
        final blockPos = block.position.toVector3();

        // 改进的分组键：法线 + 类型 + 区块坐标（避免远距离合并）
        final chunkX = (blockPos.x / 4).floor(); // 每4个单位一个区块
        final chunkZ = (blockPos.z / 4).floor();

        final key =
            '${_quantize(normal.x)},${_quantize(normal.y)},${_quantize(normal.z)},'
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
    Vector3 normal,
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
    Vector3 normal,
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
    Vector3 normal,
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
    Vector3 normal,
  ) {
    final planePos1 = _getPlaneCoordinate(face1.center, normal);
    final planePos2 = _getPlaneCoordinate(face2.center, normal);
    return (planePos1 - planePos2).abs() < _epsilon;
  }

  /// 检查两个面是否相邻
  static bool _areFacesAdjacent(
    BlockFace face1,
    BlockFace face2,
    Vector3 normal,
  ) {
    final bounds1 = _getFaceBounds(face1, normal);
    final bounds2 = _getFaceBounds(face2, normal);

    // 检查在U轴或V轴方向是否相邻
    final uAdjacent =
        (_approxEqual(bounds1.maxX, bounds2.minX) ||
            _approxEqual(bounds2.maxX, bounds1.minX)) &&
        (bounds1.minY < bounds2.maxY - _epsilon &&
            bounds1.maxY > bounds2.minY + _epsilon);

    final vAdjacent =
        (_approxEqual(bounds1.maxY, bounds2.minY) ||
            _approxEqual(bounds2.maxY, bounds1.minY)) &&
        (bounds1.minX < bounds2.maxX - _epsilon &&
            bounds1.maxX > bounds2.minX + _epsilon);

    return uAdjacent || vAdjacent;
  }

  /// 检查合并后的面是否会被遮挡
  static bool _wouldMergeBeOccluded(
    BlockFace face1,
    BlockFace face2,
    Vector3 normal,
    List<Block> allBlocks,
  ) {
    // 计算合并后的边界
    final bounds1 = _getFaceBounds3D(face1, normal);
    final bounds2 = _getFaceBounds3D(face2, normal);

    final mergedMin = Vector3(
      math.min(bounds1.item1.x, bounds2.item1.x),
      math.min(bounds1.item1.y, bounds2.item1.y),
      math.min(bounds1.item1.z, bounds2.item1.z),
    );

    final mergedMax = Vector3(
      math.max(bounds1.item2.x, bounds2.item2.x),
      math.max(bounds1.item2.y, bounds2.item2.y),
      math.max(bounds1.item2.z, bounds2.item2.z),
    );

    // 检查合并区域是否有其他方块（可能造成遮挡）
    final mergedCenter = (mergedMin + mergedMax) * 0.5;
    // 向法线方向偏移一点

    for (final block in allBlocks) {
      final blockPos = block.position.toVector3();
      final blockMin = blockPos - Vector3.all(Constants.blockSizeHalf);
      final blockMax = blockPos + Vector3.all(Constants.blockSizeHalf);

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
    Vector3 normal,
    BlockType blockType,
  ) {
    if (faces.isEmpty) return null;

    Vector3? minVec, maxVec;

    for (final face in faces) {
      final bounds = _getFaceBounds3D(face, normal);

      if (minVec == null || maxVec == null) {
        minVec = bounds.item1;
        maxVec = bounds.item2;
      } else {
        minVec = Vector3(
          math.min(minVec.x, bounds.item1.x),
          math.min(minVec.y, bounds.item1.y),
          math.min(minVec.z, bounds.item1.z),
        );
        maxVec = Vector3(
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
  static _Rectangle2D _getFaceBounds(BlockFace face, Vector3 normal) {
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
  static Tuple<Vector3, Vector3> _getFaceBounds3D(
    BlockFace face,
    Vector3 normal,
  ) {
    final vertices = face.vertices;
    double minX = double.infinity,
        minY = double.infinity,
        minZ = double.infinity;
    double maxX = -double.infinity,
        maxY = -double.infinity,
        maxZ = -double.infinity;

    for (final vertex in vertices) {
      minX = math.min(minX, vertex.x);
      minY = math.min(minY, vertex.y);
      minZ = math.min(minZ, vertex.z);
      maxX = math.max(maxX, vertex.x);
      maxY = math.max(maxY, vertex.y);
      maxZ = math.max(maxZ, vertex.z);
    }

    // 根据法线方向调整边界，确保边界准确
    if (normal.x.abs() > 0.5) {
      final x = face.center.x;
      return Tuple(Vector3(x, minY, minZ), Vector3(x, maxY, maxZ));
    } else if (normal.y.abs() > 0.5) {
      final y = face.center.y;
      return Tuple(Vector3(minX, y, minZ), Vector3(maxX, y, maxZ));
    } else {
      final z = face.center.z;
      return Tuple(Vector3(minX, minY, z), Vector3(maxX, maxY, z));
    }
  }

  // 辅助方法
  static bool _isBehindPlane(
    Vector3 point,
    Vector3 planePoint,
    Vector3 normal,
  ) {
    return (point - planePoint).dot(normal) < -_epsilon;
  }

  static bool _aabbIntersects(
    Vector3 min1,
    Vector3 max1,
    Vector3 min2,
    Vector3 max2,
  ) {
    return min1.x <= max2.x &&
        max1.x >= min2.x &&
        min1.y <= max2.y &&
        max1.y >= min2.y &&
        min1.z <= max2.z &&
        max1.z >= min2.z;
  }

  // 保留原有的辅助方法...
  static double _getPlaneCoordinate(Vector3 point, Vector3 normal) {
    if (normal.x.abs() > 0.5) return point.x;
    if (normal.y.abs() > 0.5) return point.y;
    return point.z;
  }

  static double _quantize(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  static bool _approxEqual(double a, double b) {
    return (a - b).abs() < _epsilon;
  }
}

/// 辅助类：2D矩形
class _Rectangle2D {
  final double minX, minY, maxX, maxY;

  _Rectangle2D(this.minX, this.minY, this.maxX, this.maxY);

  @override
  String toString() => 'Rectangle2D(x: $minX→$maxX, y: $minY→$maxY)';
}

/// 辅助类：元组
class Tuple<T1, T2> {
  final T1 item1;
  final T2 item2;

  Tuple(this.item1, this.item2);

  @override
  String toString() => 'Tuple($item1, $item2)';
}
