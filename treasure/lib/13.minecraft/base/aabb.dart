import 'vector.dart';

/// 轴对齐包围盒
class AABB {
  final Vector3 min, max;

  AABB(this.min, this.max);

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

  /// 将包围盒分割为8个子盒（用于八叉树）
  List<AABB> split() {
    final center = this.center;
    return [
      AABB(Vector3(min.x, min.y, min.z), Vector3(center.x, center.y, center.z)),
      AABB(Vector3(center.x, min.y, min.z), Vector3(max.x, center.y, center.z)),
      AABB(Vector3(min.x, center.y, min.z), Vector3(center.x, max.y, center.z)),
      AABB(Vector3(center.x, center.y, min.z), Vector3(max.x, max.y, center.z)),
      AABB(Vector3(min.x, min.y, center.z), Vector3(center.x, center.y, max.z)),
      AABB(Vector3(center.x, min.y, center.z), Vector3(max.x, center.y, max.z)),
      AABB(Vector3(min.x, center.y, center.z), Vector3(center.x, max.y, max.z)),
      AABB(Vector3(center.x, center.y, center.z), Vector3(max.x, max.y, max.z)),
    ];
  }
}
