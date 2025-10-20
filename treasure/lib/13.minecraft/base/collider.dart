import 'vector.dart';

/// 碰撞体类型
enum ColliderType { box }

/// 碰撞体接口
abstract class Collider {
  ColliderType get colliderType;
  Vector3 get position;
  bool checkCollision(Collider other);
  bool containsPoint(Vector3 point);
}

/// 方块碰撞体
class BoxCollider implements Collider {
  @override
  final Vector3 position;
  final Vector3 size;

  BoxCollider({required this.position, required this.size});

  Vector3 get _halfSize => size * 0.5;

  @override
  ColliderType get colliderType => ColliderType.box;

  // 边界计算
  double get minX => position.x - _halfSize.x;
  double get maxX => position.x + _halfSize.x;
  double get minY => position.y - _halfSize.y;
  double get maxY => position.y + _halfSize.y;
  double get minZ => position.z - _halfSize.z;
  double get maxZ => position.z + _halfSize.z;

  @override
  bool checkCollision(Collider other) {
    if (other is! BoxCollider) return false;

    return (minX <= other.maxX && maxX >= other.minX) &&
        (minY <= other.maxY && maxY >= other.minY) &&
        (minZ <= other.maxZ && maxZ >= other.minZ);
  }

  @override
  bool containsPoint(Vector3 point) {
    return point.x >= minX &&
        point.x <= maxX &&
        point.y >= minY &&
        point.y <= maxY &&
        point.z >= minZ &&
        point.z <= maxZ;
  }

  /// 计算与另一包围盒的重叠量
  double _calculateOverlap(double min1, double max1, double min2, double max2) {
    if (max1 <= min2 || min1 >= max2) return 0;
    final overlap1 = max1 - min2;
    final overlap2 = max2 - min1;
    return overlap1 < overlap2 ? -overlap1 : overlap2;
  }

  /// 解析与另一碰撞体的碰撞
  Vector3 resolveCollision(BoxCollider other, Vector3 oldPosition) {
    final overlapX = _calculateOverlap(minX, maxX, other.minX, other.maxX);
    final overlapY = _calculateOverlap(minY, maxY, other.minY, other.maxY);
    final overlapZ = _calculateOverlap(minZ, maxZ, other.minZ, other.maxZ);

    // 选择最小重叠方向进行解析
    if (overlapX.abs() <= overlapY.abs() && overlapX.abs() <= overlapZ.abs()) {
      return Vector3(overlapX, 0, 0);
    } else if (overlapY.abs() <= overlapX.abs() &&
        overlapY.abs() <= overlapZ.abs()) {
      return Vector3(0, overlapY, 0);
    } else {
      return Vector3(0, 0, overlapZ);
    }
  }
}
