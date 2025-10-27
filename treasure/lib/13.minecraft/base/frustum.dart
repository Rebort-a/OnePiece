import 'vector.dart';
import 'matrix.dart';
import 'aabb.dart';
import 'constant.dart';

/// 平面方程：ax + by + cz + d = 0
class Plane {
  final Vector3Unit normal; // 法向量（指向平面外部）
  final double distance; // 原点到平面的距离（d）

  Plane(this.normal, this.distance);

  /// 从平面方程系数创建平面（ax + by + cz + d = 0）
  factory Plane.fromCoefficients(double a, double b, double c, double d) {
    final vec = Vector3(a, b, c);
    final length = vec.magnitude;

    // 处理法向量为零的退化情况
    if (length < Constants.epsilon) {
      // 返回一个默认平面，例如 y=0 平面
      return Plane(Vector3Unit(0, 1, 0), 0);
    }

    // 对法向量和距离 d 同时进行归一化
    final invLength = 1.0 / length;
    return Plane(
      Vector3Unit(a * invLength, b * invLength, c * invLength),
      d * invLength,
    );
  }

  /// 判断点是否在平面内侧（视锥体内部）
  bool isPointInside(Vector3 point) =>
      distanceToPoint(point) >= -Constants.epsilon;

  /// 计算点到平面的距离
  double distanceToPoint(Vector3 point) => normal.dot(point) + distance;
}

/// 视锥体（由6个平面组成：近、远、左、右、上、下）
class Frustum {
  final List<Plane> planes;

  Frustum._(this.planes);

  /// 从视图投影矩阵构造，矩阵是列主序存储
  factory Frustum.fromViewProjectionMatrix(Matrix m) {
    return Frustum._([
      _createPlane(m[3] + m[0], m[7] + m[4], m[11] + m[8], m[15] + m[12]), // 左
      _createPlane(m[3] - m[0], m[7] - m[4], m[11] - m[8], m[15] - m[12]), // 右
      _createPlane(m[3] + m[1], m[7] + m[5], m[11] + m[9], m[15] + m[13]), // 下
      _createPlane(m[3] - m[1], m[7] - m[5], m[11] - m[9], m[15] - m[13]), // 上
      _createPlane(m[3] + m[2], m[7] + m[6], m[11] + m[10], m[15] + m[14]), // 近
      _createPlane(m[3] - m[2], m[7] - m[6], m[11] - m[10], m[15] - m[14]), // 远
    ]);
  }

  static Plane _createPlane(double a, double b, double c, double d) {
    double length = Vector3(a, b, c).magnitude;
    return length > Constants.epsilon
        ? Plane.fromCoefficients(a / length, b / length, c / length, d / length)
        : Plane(Vector3Unit(0, 1, 0), 0);
  }

  /// 检查AABB相交
  bool intersectsAABB(AABB aabb) {
    final center = aabb.center;
    final extents = aabb.extents;

    for (final plane in planes) {
      final r =
          extents.x * plane.normal.x.abs() +
          extents.y * plane.normal.y.abs() +
          extents.z * plane.normal.z.abs();

      if (plane.distanceToPoint(center) < -r - Constants.epsilon) {
        return false;
      }
    }

    return true;
  }

  /// 检查点包含
  bool containsPoint(Vector3 point) {
    return planes.every((plane) => plane.isPointInside(point));
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
