import 'dart:math' as math;

import 'constant.dart';
import 'vector.dart';

/// 轴对齐包围盒
class AABB {
  final Vector3 min, max;

  AABB(this.min, this.max);

  /// 从方块位置创建AABB
  factory AABB.fromBlockPosition(Vector3 position) {
    final halfSize = Constants.blockSizeHalf;
    return AABB(
      position - Vector3.all(halfSize),
      position + Vector3.all(halfSize),
    );
  }

  /// 检查与另一AABB是否相交
  bool intersects(AABB other) =>
      min.x <= other.max.x &&
      max.x >= other.min.x &&
      min.y <= other.max.y &&
      max.y >= other.min.y &&
      min.z <= other.max.z &&
      max.z >= other.min.z;

  /// 检查是否包含某点
  bool contains(Vector3 point) =>
      point.x >= min.x &&
      point.x <= max.x &&
      point.y >= min.y &&
      point.y <= max.y &&
      point.z >= min.z &&
      point.z <= max.z;

  /// 获取中心点
  Vector3 get center => Vector3(
    (min.x + max.x) * 0.5,
    (min.y + max.y) * 0.5,
    (min.z + max.z) * 0.5,
  );

  /// 获取包围盒尺寸
  Vector3 get size => max - min;

  /// 获取包围盒半尺寸
  Vector3 get extents => size * 0.5;

  /// 扩展包围盒以包含点
  AABB expandToInclude(Vector3 point) {
    return AABB(
      Vector3(
        math.min(min.x, point.x),
        math.min(min.y, point.y),
        math.min(min.z, point.z),
      ),
      Vector3(
        math.max(max.x, point.x),
        math.max(max.y, point.y),
        math.max(max.z, point.z),
      ),
    );
  }

  @override
  String toString() => 'AABB(min: $min, max: $max)';
}
