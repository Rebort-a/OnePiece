import 'dart:math' as math;

import 'vector.dart';
import 'matrix.dart';
import 'aabb.dart';
import 'constant.dart';

/// 平面方程：ax + by + cz + d = 0
class Plane {
  final Vector3 normal; // 法向量（指向平面外部）
  final double distance; // 原点到平面的距离（d）

  Plane(this.normal, this.distance);

  /// 从平面方程系数创建平面（ax + by + cz + d = 0）
  factory Plane.fromCoefficients(double a, double b, double c, double d) {
    final length = math.sqrt(a * a + b * b + c * c);
    if (length < Constants.epsilon) {
      return Plane(Vector3(0, 1, 0), 0);
    }
    final invLength = 1.0 / length;
    return Plane(
      Vector3(a * invLength, b * invLength, c * invLength),
      d * invLength,
    );
  }

  /// 判断点是否在平面内侧（视锥体内部）
  bool isPointInside(Vector3 point) {
    return normal.dot(point) + distance >= -Constants.epsilon;
  }

  /// 计算点到平面的距离
  double distanceToPoint(Vector3 point) {
    return normal.dot(point) + distance;
  }

  /// 判断AABB是否在平面内侧
  bool isAABBInside(AABB aabb) {
    // 找到AABB在平面法向量方向上的最远点
    final center = aabb.center;
    final extents = aabb.extents;

    final r =
        extents.x * normal.x.abs() +
        extents.y * normal.y.abs() +
        extents.z * normal.z.abs();

    final distance = distanceToPoint(center);
    return distance >= -r - Constants.epsilon;
  }

  @override
  String toString() => 'Plane(normal: $normal, distance: $distance)';
}

/// 视锥体（由6个平面组成：近、远、左、右、上、下）
class Frustum {
  final List<Plane> planes;

  Frustum(this.planes) {
    assert(planes.length == 6);
  }

  /// 从视图投影矩阵计算视锥体（修复版本）
  factory Frustum.fromViewProjectionMatrix(Matrix viewProj) {
    final m = viewProj;
    final planes = <Plane>[];

    // 左平面: m[3] + m[0], m[7] + m[4], m[11] + m[8], m[15] + m[12]
    planes.add(
      Plane.fromCoefficients(
        m[3] + m[0],
        m[7] + m[4],
        m[11] + m[8],
        m[15] + m[12],
      ),
    );

    // 右平面: m[3] - m[0], m[7] - m[4], m[11] - m[8], m[15] - m[12]
    planes.add(
      Plane.fromCoefficients(
        m[3] - m[0],
        m[7] - m[4],
        m[11] - m[8],
        m[15] - m[12],
      ),
    );

    // 下平面: m[3] + m[1], m[7] + m[5], m[11] + m[9], m[15] + m[13]
    planes.add(
      Plane.fromCoefficients(
        m[3] + m[1],
        m[7] + m[5],
        m[11] + m[9],
        m[15] + m[13],
      ),
    );

    // 上平面: m[3] - m[1], m[7] - m[5], m[11] - m[9], m[15] - m[13]
    planes.add(
      Plane.fromCoefficients(
        m[3] - m[1],
        m[7] - m[5],
        m[11] - m[9],
        m[15] - m[13],
      ),
    );

    // 近平面: m[3] + m[2], m[7] + m[6], m[11] + m[10], m[15] + m[14]
    planes.add(
      Plane.fromCoefficients(
        m[3] + m[2],
        m[7] + m[6],
        m[11] + m[10],
        m[15] + m[14],
      ),
    );

    // 远平面: m[3] - m[2], m[7] - m[6], m[11] - m[10], m[15] - m[14]
    planes.add(
      Plane.fromCoefficients(
        m[3] - m[2],
        m[7] - m[6],
        m[11] - m[10],
        m[15] - m[14],
      ),
    );

    return Frustum(planes);
  }

  /// 判断点是否在视锥体内
  bool containsPoint(Vector3 point) {
    for (final plane in planes) {
      if (!plane.isPointInside(point)) {
        return false;
      }
    }
    return true;
  }

  /// 判断AABB包围盒是否与视锥体相交
  bool intersectsAABB(AABB aabb) {
    final center = aabb.center;
    final extents = aabb.extents;

    for (final plane in planes) {
      // 计算AABB在平面法线方向上的投影半径
      final r =
          extents.x * plane.normal.x.abs() +
          extents.y * plane.normal.y.abs() +
          extents.z * plane.normal.z.abs();

      // 计算中心点到平面的距离
      final distance = plane.normal.dot(center) + plane.distance;

      // 如果整个AABB都在平面的负半空间，则被剔除
      if (distance < -r) {
        return false;
      }
    }

    return true;
  }

  /// 获取视锥体的8个角点（用于调试）
  List<Vector3> getCorners(Matrix invViewProj) {
    final corners = <Vector3>[];
    final homogenousCorners = [
      Vector4(-1, -1, -1, 1),
      Vector4(1, -1, -1, 1),
      Vector4(-1, 1, -1, 1),
      Vector4(1, 1, -1, 1),
      Vector4(-1, -1, 1, 1),
      Vector4(1, -1, 1, 1),
      Vector4(-1, 1, 1, 1),
      Vector4(1, 1, 1, 1),
    ];

    for (final corner in homogenousCorners) {
      final worldCorner = invViewProj.multiplyVector4(corner);
      corners.add(
        Vector3(
          worldCorner.x / worldCorner.w,
          worldCorner.y / worldCorner.w,
          worldCorner.z / worldCorner.w,
        ),
      );
    }

    return corners;
  }
}
