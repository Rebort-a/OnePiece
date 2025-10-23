import 'vector.dart';
import 'aabb.dart';

/// 碰撞体类型
enum ColliderType { box }

/// 碰撞体接口
abstract class Collider {
  ColliderType get colliderType;
  Vector3 get position;
  bool checkCollision(Collider other);
  bool containsPoint(Vector3 point);
}

/// 方块碰撞体（继承AABB）
class BoxCollider extends AABB implements Collider {
  BoxCollider({required Vector3 position, required Vector3 size})
    : super(
        position - (size * 0.5), // 计算min
        position + (size * 0.5), // 计算max
      );

  /// 整数版本构造函数
  factory BoxCollider.fromInt({
    required Vector3Int position,
    required Vector3Int size,
  }) {
    return BoxCollider(position: position.toVector3(), size: size.toVector3());
  }

  /// 从AABB创建
  BoxCollider.fromAABB(AABB aabb) : super(aabb.min, aabb.max);

  @override
  ColliderType get colliderType => ColliderType.box;

  @override
  Vector3 get position => center;

  // 边界计算属性（直接使用继承的min/max）
  double get minX => min.x;
  double get maxX => max.x;
  double get minY => min.y;
  double get maxY => max.y;
  double get minZ => min.z;
  double get maxZ => max.z;

  @override
  bool checkCollision(Collider other) {
    if (other is BoxCollider) {
      return intersects(other);
    }
    return false;
  }

  @override
  bool containsPoint(Vector3 point) {
    return contains(point);
  }

  /// 检查是否包含整数点
  bool containsIntPoint(Vector3Int point) {
    return contains(point.toVector3());
  }

  /// 解析与另一碰撞体的碰撞
  Vector3 resolveCollision(BoxCollider other, Vector3 oldPosition) {
    return calculateOverlap(other);
  }
}
