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

/// 方块碰撞体
class BoxCollider implements Collider {
  // 将 AABB 作为成员变量（核心改动）
  final AABB _aabb;

  // 构造函数：通过中心点和大小初始化 AABB 成员
  BoxCollider({required Vector3 position, required Vector3 size})
    : _aabb = AABB.fromCenterAndSize(position, size);

  // 整数版本构造函数
  factory BoxCollider.fromInt({
    required Vector3Int position,
    required Vector3Int size,
  }) {
    return BoxCollider(position: position.toVector3(), size: size.toVector3());
  }

  // 暴露 AABB 的部分属性（按需提供，避免直接暴露成员）
  AABB get aabb => _aabb; // 如需外部访问完整 AABB，可提供此 getter
  Vector3 get min => _aabb.min;
  Vector3 get max => _aabb.max;
  Vector3 get size => _aabb.size;

  @override
  ColliderType get colliderType => ColliderType.box;

  @override
  Vector3 get position => _aabb.center; // 位置即 AABB 的中心点

  @override
  bool checkCollision(Collider other) {
    // 仅处理与其他 BoxCollider 的碰撞，通过 AABB 成员检测重叠
    if (other is BoxCollider) {
      return _aabb.intersects(other._aabb);
    }
    return false;
  }

  @override
  bool containsPoint(Vector3 point) {
    return _aabb.contains(point); // 委托给 AABB 成员
  }

  // 检查整数点是否在碰撞体内
  bool containsIntPoint(Vector3Int point) {
    return _aabb.contains(point.toVector3());
  }

  // 计算与另一个 BoxCollider 的重叠量（用于碰撞响应）
  Vector3 resolveCollision(BoxCollider other) {
    return _aabb.calculateOverlap(other._aabb);
  }

  @override
  String toString() => 'BoxCollider(aabb: $_aabb)';
}
