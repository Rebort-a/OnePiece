import 'dart:math' as math;

import 'constant.dart';
import 'vector.dart';

/// 轴对齐包围盒
class AABB {
  final Vector3 min, max;

  AABB(this.min, this.max);

  /// 从坐标位置创建AABB
  factory AABB.fromBlockPosition(Vector3 position) {
    final halfSize = Constants.blockSizeHalf;
    return AABB(
      position - Vector3.all(halfSize),
      position + Vector3.all(halfSize),
    );
  }

  /// 从中心点和尺寸创建 AABB
  factory AABB.fromCenterAndSize(Vector3 center, Vector3 size) {
    final halfSize = size * 0.5;
    return AABB(center - halfSize, center + halfSize);
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

  /// 计算与另一AABB的重叠量
  double _calculateAxisOverlap(
    double min1,
    double max1,
    double min2,
    double max2,
  ) {
    if (max1 <= min2 + Constants.epsilon || min1 >= max2 - Constants.epsilon) {
      return 0;
    }
    final overlap1 = max1 - min2;
    final overlap2 = max2 - min1;
    return overlap1 < overlap2 ? -overlap1 : overlap2;
  }

  /// 计算与另一AABB的重叠向量
  Vector3 calculateOverlap(AABB other) {
    final overlapX = _calculateAxisOverlap(
      min.x,
      max.x,
      other.min.x,
      other.max.x,
    );
    final overlapY = _calculateAxisOverlap(
      min.y,
      max.y,
      other.min.y,
      other.max.y,
    );
    final overlapZ = _calculateAxisOverlap(
      min.z,
      max.z,
      other.min.z,
      other.max.z,
    );

    // 选择最小重叠方向
    if (overlapX.abs() <= overlapY.abs() && overlapX.abs() <= overlapZ.abs()) {
      return Vector3(overlapX, 0, 0);
    } else if (overlapY.abs() <= overlapX.abs() &&
        overlapY.abs() <= overlapZ.abs()) {
      return Vector3(0, overlapY, 0);
    } else {
      return Vector3(0, 0, overlapZ);
    }
  }

  @override
  String toString() => 'AABB(min: $min, max: $max)';
}
