import 'dart:math' as math;
import 'dart:typed_data';
import 'vector.dart';

/// 4x4 变换矩阵（列主序）
class Matrix {
  static const int size = 4;
  final Float64List data;

  Matrix.zero() : data = Float64List(size * size);
  Matrix.identity() : data = Float64List(size * size) {
    for (int i = 0; i < size; i++) {
      data[i * size + i] = 1.0;
    }
  }

  double get(int row, int col) => data[col * size + row];
  void set(int row, int col, double value) => data[col * size + row] = value;

  /// 矩阵乘法
  Matrix operator *(Matrix other) {
    final result = Matrix.zero();
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        double sum = 0.0;
        for (int i = 0; i < size; i++) {
          sum += get(row, i) * other.get(i, col);
        }
        result.set(row, col, sum);
      }
    }
    return result;
  }

  /// 变换向量
  Vector3 transformVector3(Vector3 vector) {
    final x =
        vector.x * get(0, 0) +
        vector.y * get(0, 1) +
        vector.z * get(0, 2) +
        get(0, 3);
    final y =
        vector.x * get(1, 0) +
        vector.y * get(1, 1) +
        vector.z * get(1, 2) +
        get(1, 3);
    final z =
        vector.x * get(2, 0) +
        vector.y * get(2, 1) +
        vector.z * get(2, 2) +
        get(2, 3);
    final w =
        vector.x * get(3, 0) +
        vector.y * get(3, 1) +
        vector.z * get(3, 2) +
        get(3, 3);

    return Vector3(x / w, y / w, z / w);
  }

  // 工厂方法创建常用变换矩阵
  static Matrix translation(Vector3 offset) {
    final mat = Matrix.identity();
    mat.set(0, 3, offset.x);
    mat.set(1, 3, offset.y);
    mat.set(2, 3, offset.z);
    return mat;
  }

  static Matrix rotationY(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    final mat = Matrix.identity();
    mat.set(0, 0, c);
    mat.set(0, 2, s);
    mat.set(2, 0, -s);
    mat.set(2, 2, c);
    return mat;
  }

  static Matrix perspective(
    double fovY,
    double aspect,
    double near,
    double far,
  ) {
    final f = 1.0 / math.tan(fovY / 2);
    final rangeInv = 1.0 / (near - far);

    final mat = Matrix.zero();
    mat.set(0, 0, f / aspect);
    mat.set(1, 1, f);
    mat.set(2, 2, (near + far) * rangeInv);
    mat.set(2, 3, 2 * near * far * rangeInv);
    mat.set(3, 2, -1.0);
    return mat;
  }
}
