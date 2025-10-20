import 'block.dart';
import 'vector.dart';

/// 八叉树节点
class OctreeNode {
  final Vector3 center;
  final double halfSize;
  final int maxBlocksPerNode;
  final double minHalfSize;

  final List<Block> _blocks = [];
  List<OctreeNode>? _children;

  OctreeNode({
    required this.center,
    required this.halfSize,
    required this.maxBlocksPerNode,
    required this.minHalfSize,
  });

  /// 检查位置是否在节点范围内
  bool _contains(Vector3 position) {
    final min = center.x - halfSize;
    final max = center.x + halfSize;
    if (position.x < min || position.x > max) {
      return false;
    }
    if (position.y < center.y - halfSize || position.y > center.y + halfSize) {
      return false;
    }
    if (position.z < center.z - halfSize || position.z > center.z + halfSize) {
      return false;
    }
    return true;
  }

  /// 分裂节点
  void _split() {
    if (_children != null || halfSize <= minHalfSize) return;

    final childHalfSize = halfSize / 2;
    _children = [];

    // 生成8个子节点
    for (final dx in [-1, 1]) {
      for (final dy in [-1, 1]) {
        for (final dz in [-1, 1]) {
          final childCenter = Vector3(
            center.x + dx * childHalfSize,
            center.y + dy * childHalfSize,
            center.z + dz * childHalfSize,
          );
          _children!.add(
            OctreeNode(
              center: childCenter,
              halfSize: childHalfSize,
              maxBlocksPerNode: maxBlocksPerNode,
              minHalfSize: minHalfSize,
            ),
          );
        }
      }
    }
  }

  /// 插入方块
  bool insertBlock(Block block) {
    if (!_contains(block.position)) return false;

    // 移除重复位置的方块
    _blocks.removeWhere((b) => b.position.equals(block.position));

    // 优先插入子节点
    if (_children != null) {
      for (final child in _children!) {
        if (child.insertBlock(block)) {
          _tryMerge();
          return true;
        }
      }
    }

    // 插入当前节点
    _blocks.add(block);

    // 检查是否需要分裂
    if (_blocks.length > maxBlocksPerNode && halfSize > minHalfSize) {
      _splitAndRedistribute();
    }

    return true;
  }

  /// 分裂并重新分配方块
  void _splitAndRedistribute() {
    _split();
    final blocksToMove = List<Block>.from(_blocks);
    _blocks.clear();

    for (final block in blocksToMove) {
      for (final child in _children!) {
        if (child.insertBlock(block)) break;
      }
    }
  }

  /// 删除方块
  bool removeBlock(Block block) {
    if (!_contains(block.position)) return false;

    if (_blocks.remove(block)) return true;

    if (_children != null) {
      for (final child in _children!) {
        if (child.removeBlock(block)) {
          _tryMerge();
          return true;
        }
      }
    }

    return false;
  }

  /// 查询指定位置方块
  Block? getBlock(Vector3 position) {
    if (!_contains(position)) return null;

    // 在当前节点查找
    for (final block in _blocks) {
      if (block.position.equals(position)) return block;
    }

    // 在子节点查找
    if (_children != null) {
      for (final child in _children!) {
        final found = child.getBlock(position);
        if (found != null) return found;
      }
    }

    return null;
  }

  /// 范围查询
  List<Block> queryRange(Vector3 min, Vector3 max) {
    final result = <Block>[];

    // 检查节点与查询范围是否相交
    if (_isOutsideRange(min, max)) return result;

    // 添加当前节点中的方块
    for (final block in _blocks) {
      if (_isPointInRange(block.position, min, max)) {
        result.add(block);
      }
    }

    // 递归查询子节点
    if (_children != null) {
      for (final child in _children!) {
        result.addAll(child.queryRange(min, max));
      }
    }

    return result;
  }

  /// 检查节点是否在查询范围外
  bool _isOutsideRange(Vector3 min, Vector3 max) {
    return center.x - halfSize > max.x ||
        center.x + halfSize < min.x ||
        center.y - halfSize > max.y ||
        center.y + halfSize < min.y ||
        center.z - halfSize > max.z ||
        center.z + halfSize < min.z;
  }

  /// 检查点是否在范围内
  bool _isPointInRange(Vector3 point, Vector3 min, Vector3 max) {
    return point.x >= min.x &&
        point.x <= max.x &&
        point.y >= min.y &&
        point.y <= max.y &&
        point.z >= min.z &&
        point.z <= max.z;
  }

  /// 尝试合并子节点
  void _tryMerge() {
    if (_children == null) return;

    // 检查所有子节点是否都是叶子节点且总方块数较少
    int totalBlocks = 0;
    for (final child in _children!) {
      if (child._children != null) return; // 有非叶子节点，不合并
      totalBlocks += child._blocks.length;
    }

    final mergeThreshold = (maxBlocksPerNode / 3).ceil().clamp(
      1,
      maxBlocksPerNode,
    );
    if (totalBlocks <= mergeThreshold) {
      _merge();
    }
  }

  /// 合并子节点
  void _merge() {
    if (_children == null) return;

    for (final child in _children!) {
      _blocks.addAll(child._blocks);
    }
    _children = null;
  }
}

/// 八叉树管理器
class BlockOctree {
  final OctreeNode root;

  BlockOctree({
    required Vector3 center,
    required double worldSize,
    int maxBlocksPerNode = 8,
    double minHalfSize = 4,
  }) : root = OctreeNode(
         center: center,
         halfSize: worldSize / 2,
         maxBlocksPerNode: maxBlocksPerNode,
         minHalfSize: minHalfSize,
       );

  // 代理方法
  bool insertBlock(Block block) => root.insertBlock(block);
  bool removeBlock(Block block) => root.removeBlock(block);
  Block? getBlock(Vector3 position) => root.getBlock(position);
  List<Block> queryRange(Vector3 min, Vector3 max) => root.queryRange(min, max);
  void clear() => root._blocks.clear();
}
