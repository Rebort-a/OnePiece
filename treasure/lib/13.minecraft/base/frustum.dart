import 'aabb.dart';
import 'matrix.dart';
import 'vector.dart';

class Plane {
  Vector3 normal;
  double distance;
  Plane(this.normal, this.distance);
  double distanceToPoint(Vector3 p) => normal.dot(p) - distance;
}

class Frustum {
  final List<Plane> planes = List.generate(6, (_) => Plane(Vector3.zero, 0));

  /*  再反向：normal 与 distance 全部取反  */
  void update(Matrix vp) {
    final m = vp.data;
    Plane make(int a, int b) {
      final n = Vector3(m[a] - m[b], m[a + 4] - m[b + 4], m[a + 8] - m[b + 8]);
      final d = m[a + 12] - m[b + 12];
      return Plane(-n, -d); // ← 关键：平面反向
    }

    planes[0] = make(3, 0); // 左
    planes[1] = make(0, 3); // 右
    planes[2] = make(3, 1); // 下
    planes[3] = make(1, 3); // 上
    planes[4] = make(3, 2); // 近
    planes[5] = make(2, 3); // 远

    for (final p in planes) {
      final len = p.normal.magnitude;
      p.normal /= len;
      p.distance /= len;
    }
  }

  bool aabbInside(AABB box) {
    for (final pl in planes) {
      final vertex = Vector3(
        pl.normal.x > 0 ? box.max.x : box.min.x,
        pl.normal.y > 0 ? box.max.y : box.min.y,
        pl.normal.z > 0 ? box.max.z : box.min.z,
      );
      if (pl.distanceToPoint(vertex) < 0) return false;
    }
    return true;
  }
}
