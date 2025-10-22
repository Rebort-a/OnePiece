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
    final normal = Vector3(a, b, c).normalized;
    // 确保距离与法向量方向一致
    final len = Vector3(a, b, c).magnitude;
    return Plane(normal, d / len);
  }

  /// 判断点是否在平面内侧（视锥体内部）
  bool isPointInside(Vector3 point) {
    return normal.dot(point) + distance >= -Constants.epsilon;
  }

  /// 归一化平面（确保法向量为单位向量）
  Plane normalized() {
    final len = normal.magnitude;
    return Plane(normal / len, distance / len);
  }
}

/// 视锥体（由6个平面组成：近、远、左、右、上、下）
class Frustum {
  final Plane near;
  final Plane far;
  final Plane left;
  final Plane right;
  final Plane top;
  final Plane bottom;

  Frustum({
    required this.near,
    required this.far,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  /// 从视图投影矩阵计算视锥体（左手坐标系）
  factory Frustum.fromViewProjectionMatrix(Matrix viewProj) {
    // 提取矩阵行（列主序存储，行索引 = 列*4 + 行）
    final row0 = Vector4(
      viewProj.getColumnRow(0, 0),
      viewProj.getColumnRow(1, 0),
      viewProj.getColumnRow(2, 0),
      viewProj.getColumnRow(3, 0),
    );
    final row1 = Vector4(
      viewProj.getColumnRow(0, 1),
      viewProj.getColumnRow(1, 1),
      viewProj.getColumnRow(2, 1),
      viewProj.getColumnRow(3, 1),
    );
    final row2 = Vector4(
      viewProj.getColumnRow(0, 2),
      viewProj.getColumnRow(1, 2),
      viewProj.getColumnRow(2, 2),
      viewProj.getColumnRow(3, 2),
    );
    final row3 = Vector4(
      viewProj.getColumnRow(0, 3),
      viewProj.getColumnRow(1, 3),
      viewProj.getColumnRow(2, 3),
      viewProj.getColumnRow(3, 3),
    );

    // 计算6个平面（行组合：row3 ± rowN）
    final nearPlane = Plane.fromCoefficients(
      row2.x,
      row2.y,
      row2.z,
      row2.w,
    ).normalized();
    final farPlane = Plane.fromCoefficients(
      row3.x - row2.x,
      row3.y - row2.y,
      row3.z - row2.z,
      row3.w - row2.w,
    ).normalized();
    final leftPlane = Plane.fromCoefficients(
      row3.x + row0.x,
      row3.y + row0.y,
      row3.z + row0.z,
      row3.w + row0.w,
    ).normalized();
    final rightPlane = Plane.fromCoefficients(
      row3.x - row0.x,
      row3.y - row0.y,
      row3.z - row0.z,
      row3.w - row0.w,
    ).normalized();
    final bottomPlane = Plane.fromCoefficients(
      row3.x + row1.x,
      row3.y + row1.y,
      row3.z + row1.z,
      row3.w + row1.w,
    ).normalized();
    final topPlane = Plane.fromCoefficients(
      row3.x - row1.x,
      row3.y - row1.y,
      row3.z - row1.z,
      row3.w - row1.w,
    ).normalized();

    return Frustum(
      near: nearPlane,
      far: farPlane,
      left: leftPlane,
      right: rightPlane,
      top: topPlane,
      bottom: bottomPlane,
    );
  }

  /// 判断点是否在视锥体内
  bool containsPoint(Vector3 point) {
    return near.isPointInside(point) &&
        far.isPointInside(point) &&
        left.isPointInside(point) &&
        right.isPointInside(point) &&
        top.isPointInside(point) &&
        bottom.isPointInside(point);
  }

  /// 判断AABB包围盒是否与视锥体相交
  bool intersectsAABB(AABB aabb) {
    // 检查包围盒8个顶点是否至少有一个在视锥体内
    final corners = [
      aabb.min,
      Vector3(aabb.max.x, aabb.min.y, aabb.min.z),
      Vector3(aabb.min.x, aabb.max.y, aabb.min.z),
      Vector3(aabb.max.x, aabb.max.y, aabb.min.z),
      Vector3(aabb.min.x, aabb.min.y, aabb.max.z),
      Vector3(aabb.max.x, aabb.min.y, aabb.max.z),
      Vector3(aabb.min.x, aabb.max.y, aabb.max.z),
      aabb.max,
    ];

    for (final corner in corners) {
      if (containsPoint(corner)) {
        return true;
      }
    }

    // 检查包围盒是否完全包含视锥体（极端情况）
    // 此处简化处理，实际可补充更复杂的相交检测
    return false;
  }
}
