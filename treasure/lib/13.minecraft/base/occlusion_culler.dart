import 'dart:math' as math;
import 'vector.dart';
import 'aabb.dart';
import 'constant.dart';

/// 遮挡查询结果
enum OcclusionResult { visible, occluded, partial }

/// 优化的遮挡剔除器
class OcclusionCuller {
  final List<AABB> _occluders = [];

  void clear() => _occluders.clear();

  void addOccluder(AABB occluder) => _occluders.add(occluder);

  int get count => _occluders.length;

  /// 检查遮挡状态
  OcclusionResult checkOcclusion(AABB bounds, Vector3 camera) {
    if (_occluders.isEmpty) return OcclusionResult.visible;

    // 近距离物体总是可见
    if ((bounds.center - camera).magnitude < 2.0) {
      return OcclusionResult.visible;
    }

    final corners = _getAABBCorners(bounds);
    final visibleCount = corners
        .where((corner) => _isCornerVisible(corner, camera, bounds))
        .length;

    return visibleCount == 0
        ? OcclusionResult.occluded
        : visibleCount == corners.length
        ? OcclusionResult.visible
        : OcclusionResult.partial;
  }

  /// 检查角点可见性
  bool _isCornerVisible(Vector3 corner, Vector3 camera, AABB target) {
    final ray = _Ray(origin: camera, direction: (corner - camera).normalized);
    final maxDist = (corner - camera).magnitude;

    if (maxDist < 1.0) return true;

    for (final occluder in _occluders) {
      if (_aabbEquals(occluder, target)) continue;

      final intersection = _rayAABBIntersection(ray, occluder, maxDist);
      if (intersection != null && intersection < maxDist) {
        return false;
      }
    }

    return true;
  }

  /// 射线-AABB相交检测
  double? _rayAABBIntersection(_Ray ray, AABB aabb, double maxDist) {
    final invDir = Vector3(
      1.0 /
          (ray.direction.x.abs() > Constants.epsilon
              ? ray.direction.x
              : Constants.epsilon),
      1.0 /
          (ray.direction.y.abs() > Constants.epsilon
              ? ray.direction.y
              : Constants.epsilon),
      1.0 /
          (ray.direction.z.abs() > Constants.epsilon
              ? ray.direction.z
              : Constants.epsilon),
    );

    final t1 = (aabb.min.x - ray.origin.x) * invDir.x;
    final t2 = (aabb.max.x - ray.origin.x) * invDir.x;
    final t3 = (aabb.min.y - ray.origin.y) * invDir.y;
    final t4 = (aabb.max.y - ray.origin.y) * invDir.y;
    final t5 = (aabb.min.z - ray.origin.z) * invDir.z;
    final t6 = (aabb.max.z - ray.origin.z) * invDir.z;

    final tmin = math.max(
      math.max(math.min(t1, t2), math.min(t3, t4)),
      math.min(t5, t6),
    );
    final tmax = math.min(
      math.min(math.max(t1, t2), math.max(t3, t4)),
      math.max(t5, t6),
    );

    return (tmax >= 0 && tmin <= tmax && tmin <= maxDist) ? tmin : null;
  }

  // 辅助方法
  List<Vector3> _getAABBCorners(AABB aabb) => [
    aabb.min,
    Vector3(aabb.max.x, aabb.min.y, aabb.min.z),
    Vector3(aabb.min.x, aabb.max.y, aabb.min.z),
    Vector3(aabb.max.x, aabb.max.y, aabb.min.z),
    Vector3(aabb.min.x, aabb.min.y, aabb.max.z),
    Vector3(aabb.max.x, aabb.min.y, aabb.max.z),
    Vector3(aabb.min.x, aabb.max.y, aabb.max.z),
    aabb.max,
  ];

  bool _aabbEquals(AABB a, AABB b) => a.min == b.min && a.max == b.max;

  int get occludersCount => _occluders.length;
}

/// 射线表示
class _Ray {
  final Vector3 origin;
  final Vector3 direction;

  _Ray({required this.origin, required this.direction});
}
