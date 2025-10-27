// occlusion_culler.dart - 修复版本
import 'dart:math' as math;
import 'vector.dart';
import 'aabb.dart';
import 'constant.dart';

/// 遮挡查询结果
enum OcclusionResult {
  visible, // 完全可见
  occluded, // 完全被遮挡
  partial, // 部分遮挡
}

/// 修复的遮挡剔除器
class OcclusionCuller {
  final List<AABB> _occluders = [];

  void clear() {
    _occluders.clear();
  }

  void addOccluder(AABB occluder) {
    _occluders.add(occluder);
  }

  /// 检查AABB是否被遮挡
  OcclusionResult checkOcclusion(AABB bounds, Vector3 cameraPosition) {
    if (_occluders.isEmpty) {
      return OcclusionResult.visible;
    }

    // 1. 距离检查：太近的物体不应该被剔除
    final distance = (bounds.center - cameraPosition).magnitude;
    if (distance < 2.0) {
      // 2个单位内的物体总是可见
      return OcclusionResult.visible;
    }

    // 2. 获取AABB的8个角点
    final corners = _getAABBCorners(bounds);

    int visibleCorners = 0;
    int totalTests = 0;

    // 3. 对每个角点进行遮挡测试
    for (final corner in corners) {
      final isVisible = _isCornerVisible(corner, cameraPosition, bounds);
      if (isVisible) {
        visibleCorners++;
      }
      totalTests++;
    }

    // 4. 根据可见角点数量决定结果
    if (visibleCorners == 0) {
      return OcclusionResult.occluded;
    } else if (visibleCorners == totalTests) {
      return OcclusionResult.visible;
    } else {
      return OcclusionResult.partial;
    }
  }

  /// 获取AABB的8个角点
  List<Vector3> _getAABBCorners(AABB aabb) {
    return [
      aabb.min,
      Vector3(aabb.max.x, aabb.min.y, aabb.min.z),
      Vector3(aabb.min.x, aabb.max.y, aabb.min.z),
      Vector3(aabb.max.x, aabb.max.y, aabb.min.z),
      Vector3(aabb.min.x, aabb.min.y, aabb.max.z),
      Vector3(aabb.max.x, aabb.min.y, aabb.max.z),
      Vector3(aabb.min.x, aabb.max.y, aabb.max.z),
      aabb.max,
    ];
  }

  /// 检查角点是否可见（修复版本）
  bool _isCornerVisible(
    Vector3 corner,
    Vector3 cameraPosition,
    AABB targetBounds,
  ) {
    final rayOrigin = cameraPosition;
    final rayDirection = (corner - cameraPosition).normalized;
    final maxDistance = (corner - cameraPosition).magnitude;

    // 早期拒绝：如果距离很近，直接返回可见
    if (maxDistance < 1.0) {
      return true;
    }

    // 对每个遮挡物进行测试
    for (final occluder in _occluders) {
      // 跳过目标物体自身
      if (_aabbEquals(occluder, targetBounds)) {
        continue;
      }

      // 早期拒绝：如果遮挡物在目标后面，跳过
      final occluderCenter = occluder.center;
      final toOccluder = occluderCenter - cameraPosition;
      final toTarget = corner - cameraPosition;

      if (toOccluder.magnitude > toTarget.magnitude) {
        continue; // 遮挡物在目标后面，跳过
      }

      // 检查射线是否与遮挡物相交
      final intersection = _rayAABBIntersection(
        rayOrigin,
        rayDirection,
        occluder,
        maxDistance,
      );

      if (intersection != null && intersection < maxDistance) {
        // 找到遮挡物，且遮挡物在目标之前
        return false;
      }
    }

    return true;
  }

  /// 射线与AABB相交检测（修复版本）
  double? _rayAABBIntersection(
    Vector3 rayOrigin,
    Vector3 rayDirection,
    AABB aabb,
    double maxDistance,
  ) {
    final invDir = Vector3(
      1.0 /
          (rayDirection.x.abs() < Constants.epsilon
              ? Constants.epsilon
              : rayDirection.x),
      1.0 /
          (rayDirection.y.abs() < Constants.epsilon
              ? Constants.epsilon
              : rayDirection.y),
      1.0 /
          (rayDirection.z.abs() < Constants.epsilon
              ? Constants.epsilon
              : rayDirection.z),
    );

    final t1 = (aabb.min.x - rayOrigin.x) * invDir.x;
    final t2 = (aabb.max.x - rayOrigin.x) * invDir.x;
    final t3 = (aabb.min.y - rayOrigin.y) * invDir.y;
    final t4 = (aabb.max.y - rayOrigin.y) * invDir.y;
    final t5 = (aabb.min.z - rayOrigin.z) * invDir.z;
    final t6 = (aabb.max.z - rayOrigin.z) * invDir.z;

    final tmin = math.max(
      math.max(math.min(t1, t2), math.min(t3, t4)),
      math.min(t5, t6),
    );
    final tmax = math.min(
      math.min(math.max(t1, t2), math.max(t3, t4)),
      math.max(t5, t6),
    );

    // 如果tmax < 0，射线在AABB后面
    if (tmax < 0) {
      return null;
    }

    // 如果tmin > tmax，没有相交
    if (tmin > tmax) {
      return null;
    }

    // 如果tmin > maxDistance，交点太远
    if (tmin > maxDistance) {
      return null;
    }

    // 返回最近的交点距离
    return tmin >= 0 ? tmin : tmax;
  }

  /// 检查两个AABB是否相等
  bool _aabbEquals(AABB a, AABB b) {
    return a.min == b.min && a.max == b.max;
  }

  int get occludersCount => _occluders.length;
}
