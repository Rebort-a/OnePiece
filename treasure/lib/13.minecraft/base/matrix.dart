import 'dart:math' as math;
import 'vector.dart';

class Matrix {
  // 存储4x4矩阵元素（列主序：[c0r0, c0r1, c0r2, c0r3, c1r0, ..., c3r3]）
  final List<double> _values;

  // 构造函数
  Matrix.zero() : _values = List.filled(16, 0.0);
  Matrix.identity() : _values = List.filled(16, 0.0) {
    _values[0] = 1.0; // c0r0
    _values[5] = 1.0; // c1r1
    _values[10] = 1.0; // c2r2
    _values[15] = 1.0; // c3r3
  }
  Matrix.fromList(List<double> list) : _values = List.from(list) {
    assert(list.length == 16, "Matrix must have 16 elements");
  }

  // 索引访问（column: 0-3, row: 0-3）
  double operator [](int index) => _values[index];
  void operator []=(int index, double value) => _values[index] = value;
  double getColumnRow(int column, int row) => _values[column * 4 + row];
  void setColumnRow(int column, int row, double value) =>
      _values[column * 4 + row] = value;

  // 矩阵乘法（this * other）
  Matrix multiply(Matrix other) {
    final result = Matrix.zero();
    for (int col = 0; col < 4; col++) {
      for (int row = 0; row < 4; row++) {
        double sum = 0.0;
        for (int i = 0; i < 4; i++) {
          sum += getColumnRow(i, row) * other.getColumnRow(col, i);
        }
        result.setColumnRow(col, row, sum);
      }
    }
    return result;
  }

  // 与3D向量相乘（齐次坐标：w=1）
  Vector3 multiplyVector3(Vector3 vector) {
    final x =
        vector.x * _values[0] +
        vector.y * _values[4] +
        vector.z * _values[8] +
        1.0 * _values[12];
    final y =
        vector.x * _values[1] +
        vector.y * _values[5] +
        vector.z * _values[9] +
        1.0 * _values[13];
    final z =
        vector.x * _values[2] +
        vector.y * _values[6] +
        vector.z * _values[10] +
        1.0 * _values[14];
    final w =
        vector.x * _values[3] +
        vector.y * _values[7] +
        vector.z * _values[11] +
        1.0 * _values[15];
    // 透视除法（齐次坐标转3D坐标）
    return Vector3(x / w, y / w, z / w);
  }

  // 转置矩阵（行和列互换）
  Matrix transpose() {
    final result = Matrix.zero();
    for (int col = 0; col < 4; col++) {
      for (int row = 0; row < 4; row++) {
        result.setColumnRow(row, col, getColumnRow(col, row));
      }
    }
    return result;
  }

  // 生成平移矩阵
  static Matrix translation(Vector3 offset) {
    final mat = Matrix.identity();
    mat.setColumnRow(3, 0, offset.x); // 平移X
    mat.setColumnRow(3, 1, offset.y); // 平移Y
    mat.setColumnRow(3, 2, offset.z); // 平移Z
    return mat;
  }

  // 生成缩放矩阵
  static Matrix scaling(Vector3 scale) {
    final mat = Matrix.identity();
    mat.setColumnRow(0, 0, scale.x);
    mat.setColumnRow(1, 1, scale.y);
    mat.setColumnRow(2, 2, scale.z);
    return mat;
  }

  // 生成绕X轴旋转矩阵（弧度）
  static Matrix rotationX(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    final mat = Matrix.identity();
    mat.setColumnRow(1, 1, c);
    mat.setColumnRow(1, 2, s);
    mat.setColumnRow(2, 1, -s);
    mat.setColumnRow(2, 2, c);
    return mat;
  }

  // 生成绕Y轴旋转矩阵（弧度）
  static Matrix rotationY(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    final mat = Matrix.identity();
    mat.setColumnRow(0, 0, c);
    mat.setColumnRow(0, 2, -s);
    mat.setColumnRow(2, 0, s);
    mat.setColumnRow(2, 2, c);
    return mat;
  }

  // 生成绕Z轴旋转矩阵（弧度）
  static Matrix rotationZ(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    final mat = Matrix.identity();
    mat.setColumnRow(0, 0, c);
    mat.setColumnRow(0, 1, s);
    mat.setColumnRow(1, 0, -s);
    mat.setColumnRow(1, 1, c);
    return mat;
  }

  // 生成透视投影矩阵
  // fovY: 垂直视场角（弧度）, aspect: 宽高比, near: 近平面, far: 远平面
  static Matrix perspective(
    double fovY,
    double aspect,
    double near,
    double far,
  ) {
    final f = 1.0 / math.tan(fovY / 2.0);
    final rangeInv = 1.0 / (near - far);
    final mat = Matrix.zero();
    mat.setColumnRow(0, 0, f / aspect);
    mat.setColumnRow(1, 1, f);
    mat.setColumnRow(2, 2, (near + far) * rangeInv);
    mat.setColumnRow(2, 3, -1.0);
    mat.setColumnRow(3, 2, 2 * near * far * rangeInv);
    return mat;
  }

  // 生成视图矩阵（相机变换的逆矩阵）
  static Matrix lookAt(Vector3 eye, Vector3 target, Vector3 up) {
    final forward = (target - eye).normalized;

    // 修正：使用正确的叉乘顺序
    final right = up.normalized.cross(forward).normalized;
    final correctedUp = forward.cross(right).normalized;

    // 旋转矩阵（相机朝向）
    final rotation = Matrix.identity()
      ..setColumnRow(0, 0, right.x)
      ..setColumnRow(0, 1, right.y)
      ..setColumnRow(0, 2, right.z)
      ..setColumnRow(1, 0, correctedUp.x)
      ..setColumnRow(1, 1, correctedUp.y)
      ..setColumnRow(1, 2, correctedUp.z)
      ..setColumnRow(2, 0, -forward.x)
      ..setColumnRow(2, 1, -forward.y)
      ..setColumnRow(2, 2, -forward.z);

    // 平移矩阵（相机位置的反向）
    final translation = Matrix.translation(-eye);

    // 视图矩阵 = 旋转 * 平移
    return rotation.multiply(translation);
  }

  Vector4 multiplyVector4(Vector4 v) {
    return Vector4(
      v.x * _values[0] +
          v.y * _values[4] +
          v.z * _values[8] +
          v.w * _values[12],
      v.x * _values[1] +
          v.y * _values[5] +
          v.z * _values[9] +
          v.w * _values[13],
      v.x * _values[2] +
          v.y * _values[6] +
          v.z * _values[10] +
          v.w * _values[14],
      v.x * _values[3] +
          v.y * _values[7] +
          v.z * _values[11] +
          v.w * _values[15],
    );
  }

  // 绕任意轴旋转（axis 必须为单位向量）
  static Matrix fromAxisAngle(Vector3Unit axis, double radians) {
    final x = axis.x, y = axis.y, z = axis.z;
    final c = math.cos(radians);
    final s = math.sin(radians);
    final t = 1 - c;

    return Matrix.fromList([
      t * x * x + c,
      t * x * y - s * z,
      t * x * z + s * y,
      0,
      t * x * y + s * z,
      t * y * y + c,
      t * y * z - s * x,
      0,
      t * x * z - s * y,
      t * y * z + s * x,
      t * z * z + c,
      0,
      0,
      0,
      0,
      1,
    ]);
  }

  // 在 Matrix 类中添加正确的左手坐标系视图矩阵
  static Matrix lookAtLH(Vector3 eye, Vector3 target, Vector3 up) {
    final forward = (target - eye).normalized; // z轴（向里）
    final right = up.cross(forward).normalized; // x轴（向右）
    final newUp = forward.cross(right).normalized; // y轴（向上）

    return Matrix.fromList([
      right.x,
      newUp.x,
      forward.x,
      0,
      right.y,
      newUp.y,
      forward.y,
      0,
      right.z,
      newUp.z,
      forward.z,
      0,
      -right.dot(eye),
      -newUp.dot(eye),
      -forward.dot(eye),
      1,
    ]);
  }

  // 左手坐标系透视投影矩阵
  static Matrix perspectiveLH(
    double fovY,
    double aspect,
    double near,
    double far,
  ) {
    final h = 1.0 / math.tan(fovY * 0.5);
    final w = h / aspect;
    final range = far / (far - near);

    return Matrix.fromList([
      w, 0, 0, 0,
      0, h, 0, 0, // ✅ 不翻转Y轴
      0, 0, range, 1,
      0, 0, -range * near, 0,
    ]);
  }
}
