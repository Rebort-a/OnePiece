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

  Matrix.fromList(List<double> list) : _values = List.filled(16, 0.0) {
    final copyLength = list.length < 16 ? list.length : 16;
    for (int i = 0; i < copyLength; i++) {
      _values[i] = list[i];
    }
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
    mat.setColumnRow(0, 2, s);
    mat.setColumnRow(2, 0, -s);
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
    final right = forward.cross(up).normalized;
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
      t * x * x + c, // c0r0
      t * x * y + s * z, // c0r1
      t * x * z - s * y, // c0r2
      0,
      t * x * y - s * z, // c1r0
      t * y * y + c, // c1r1
      t * y * z + s * x, // c1r2
      0,
      t * x * z + s * y, // c2r0
      t * y * z - s * x, // c2r1
      t * z * z + c, // c2r2
      0,
      0, 0, 0, 1,
    ]);
  }

  // 在 Matrix 类中添加正确的左手坐标系视图矩阵
  static Matrix lookAtLH(Vector3 eye, Vector3 target, Vector3Unit up) {
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
      0, h, 0, 0, // 不翻转Y轴
      0, 0, range, 1,
      0, 0, -range * near, 0,
    ]);
  }

  /// 计算矩阵的逆矩阵
  Matrix inverse() {
    // 使用伴随矩阵法计算逆矩阵
    final det = determinant();
    if (det.abs() < 1e-10) {
      throw Exception("Matrix is singular and cannot be inverted");
    }

    return adjugate() * (1.0 / det);
  }

  /// 计算矩阵的行列式
  double determinant() {
    // 4x4 矩阵的行列式计算
    final a00 = _values[0],
        a01 = _values[4],
        a02 = _values[8],
        a03 = _values[12];
    final a10 = _values[1],
        a11 = _values[5],
        a12 = _values[9],
        a13 = _values[13];
    final a20 = _values[2],
        a21 = _values[6],
        a22 = _values[10],
        a23 = _values[14];
    final a30 = _values[3],
        a31 = _values[7],
        a32 = _values[11],
        a33 = _values[15];

    return a00 * _det3x3(a11, a12, a13, a21, a22, a23, a31, a32, a33) -
        a01 * _det3x3(a10, a12, a13, a20, a22, a23, a30, a32, a33) +
        a02 * _det3x3(a10, a11, a13, a20, a21, a23, a30, a31, a33) -
        a03 * _det3x3(a10, a11, a12, a20, a21, a22, a30, a31, a32);
  }

  /// 计算3x3矩阵的行列式
  double _det3x3(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
    double g,
    double h,
    double i,
  ) {
    return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
  }

  /// 计算伴随矩阵（余子式矩阵的转置）
  Matrix adjugate() {
    final a00 = _values[0],
        a01 = _values[4],
        a02 = _values[8],
        a03 = _values[12];
    final a10 = _values[1],
        a11 = _values[5],
        a12 = _values[9],
        a13 = _values[13];
    final a20 = _values[2],
        a21 = _values[6],
        a22 = _values[10],
        a23 = _values[14];
    final a30 = _values[3],
        a31 = _values[7],
        a32 = _values[11],
        a33 = _values[15];

    // 计算所有2x2子矩阵的行列式
    final b00 = a00 * a11 - a01 * a10;
    final b01 = a00 * a12 - a02 * a10;
    final b02 = a00 * a13 - a03 * a10;
    final b03 = a01 * a12 - a02 * a11;
    final b04 = a01 * a13 - a03 * a11;
    final b05 = a02 * a13 - a03 * a12;
    final b06 = a20 * a31 - a21 * a30;
    final b07 = a20 * a32 - a22 * a30;
    final b08 = a20 * a33 - a23 * a30;
    final b09 = a21 * a32 - a22 * a31;
    final b10 = a21 * a33 - a23 * a31;
    final b11 = a22 * a33 - a23 * a32;

    // 计算伴随矩阵（注意符号交替）
    final det00 = (a11 * b11 - a12 * b10 + a13 * b09);
    final det01 = -(a10 * b11 - a12 * b08 + a13 * b07);
    final det02 = (a10 * b10 - a11 * b08 + a13 * b06);
    final det03 = -(a10 * b09 - a11 * b07 + a12 * b06);

    final det10 = -(a01 * b11 - a02 * b10 + a03 * b09);
    final det11 = (a00 * b11 - a02 * b08 + a03 * b07);
    final det12 = -(a00 * b10 - a01 * b08 + a03 * b06);
    final det13 = (a00 * b09 - a01 * b07 + a02 * b06);

    final det20 = (a01 * b05 - a02 * b04 + a03 * b03);
    final det21 = -(a00 * b05 - a02 * b02 + a03 * b01);
    final det22 = (a00 * b04 - a01 * b02 + a03 * b00);
    final det23 = -(a00 * b03 - a01 * b01 + a02 * b00);

    final det30 = -(a01 * b08 - a02 * b07 + a03 * b06);
    final det31 = (a00 * b08 - a02 * b05 + a03 * b04);
    final det32 = -(a00 * b07 - a01 * b05 + a03 * b03);
    final det33 = (a00 * b06 - a01 * b04 + a02 * b03);

    return Matrix.fromList([
      det00,
      det01,
      det02,
      det03,
      det10,
      det11,
      det12,
      det13,
      det20,
      det21,
      det22,
      det23,
      det30,
      det31,
      det32,
      det33,
    ]);
  }

  /// 矩阵标量乘法
  Matrix operator *(double scalar) {
    final result = Matrix.zero();
    for (int i = 0; i < 16; i++) {
      result._values[i] = _values[i] * scalar;
    }
    return result;
  }

  /// 检查矩阵是否可逆
  bool get isInvertible {
    return determinant().abs() > 1e-10;
  }

  /// 计算矩阵的迹（对角元素之和）
  double get trace {
    return _values[0] + _values[5] + _values[10] + _values[15];
  }

  /// 计算转置逆矩阵（有时比先逆后转置更高效）
  Matrix inverseTranspose() {
    return inverse().transpose();
  }

  /// 快速逆矩阵计算（针对特殊类型的矩阵）
  /// 适用于视图矩阵等正交矩阵
  Matrix fastInverse() {
    // 对于正交矩阵，逆矩阵等于转置矩阵
    // 这里我们检查矩阵是否接近正交
    final product = multiply(transpose());
    final identity = Matrix.identity();

    bool isOrthogonal = true;
    for (int i = 0; i < 16 && isOrthogonal; i++) {
      if ((product._values[i] - identity._values[i]).abs() > 1e-5) {
        isOrthogonal = false;
      }
    }

    if (isOrthogonal) {
      return transpose();
    } else {
      return inverse();
    }
  }

  /// 计算视图矩阵的逆（优化版本）
  /// 视图矩阵的逆就是相机变换矩阵
  Matrix inverseView() {
    // 提取旋转部分（3x3左上角）
    final r00 = _values[0], r01 = _values[4], r02 = _values[8];
    final r10 = _values[1], r11 = _values[5], r12 = _values[9];
    final r20 = _values[2], r21 = _values[6], r22 = _values[10];

    // 提取平移部分
    final t0 = _values[12], t1 = _values[13], t2 = _values[14];

    // 对于正交矩阵，逆旋转就是转置
    // 逆平移 = -R^T * T
    final invT0 = -(r00 * t0 + r10 * t1 + r20 * t2);
    final invT1 = -(r01 * t0 + r11 * t1 + r21 * t2);
    final invT2 = -(r02 * t0 + r12 * t1 + r22 * t2);

    return Matrix.fromList([
      r00,
      r01,
      r02,
      0,
      r10,
      r11,
      r12,
      0,
      r20,
      r21,
      r22,
      0,
      invT0,
      invT1,
      invT2,
      1,
    ]);
  }
}

/// 4x4 整数矩阵（列主序存储）
/// 适用于整数精度的坐标变换、网格计算等场景
class MatrixInt {
  // 存储4x4矩阵元素（列主序：[c0r0, c0r1, c0r2, c0r3, c1r0, ..., c3r3]）
  final List<int> _values;

  // -------------------------- 构造函数 --------------------------
  /// 全零矩阵
  MatrixInt.zero() : _values = List.filled(16, 0);

  /// 单位矩阵（对角线为1，其余为0）
  MatrixInt.identity() : _values = List.filled(16, 0) {
    _values[0] = 1; // c0r0
    _values[5] = 1; // c1r1
    _values[10] = 1; // c2r2
    _values[15] = 1; // c3r3
  }

  /// 从整数列表初始化矩阵（不足16个元素补0，超出部分忽略）
  MatrixInt.fromList(List<int> list) : _values = List.filled(16, 0) {
    final copyLength = list.length < 16 ? list.length : 16;
    for (int i = 0; i < copyLength; i++) {
      _values[i] = list[i];
    }
  }

  // -------------------------- 元素访问 --------------------------
  /// 通过索引访问元素（0-15，列主序）
  int operator [](int index) => _values[index];

  /// 通过索引设置元素（0-15，列主序）
  void operator []=(int index, int value) => _values[index] = value;

  /// 通过列和行访问元素（column: 0-3, row: 0-3）
  int getColumnRow(int column, int row) => _values[column * 4 + row];

  /// 通过列和行设置元素（column: 0-3, row: 0-3）
  void setColumnRow(int column, int row, int value) =>
      _values[column * 4 + row] = value;

  // -------------------------- 矩阵运算 --------------------------
  /// 矩阵乘法（this * other，结果为整数矩阵）
  /// 注意：整数乘法可能导致溢出，需自行确保数值范围
  MatrixInt multiply(MatrixInt other) {
    final result = MatrixInt.zero();
    for (int col = 0; col < 4; col++) {
      for (int row = 0; row < 4; row++) {
        int sum = 0;
        for (int i = 0; i < 4; i++) {
          sum += getColumnRow(i, row) * other.getColumnRow(col, i);
        }
        result.setColumnRow(col, row, sum);
      }
    }
    return result;
  }

  /// 与三维整数向量相乘（齐次坐标 w=1，结果为整数向量）
  /// 适用于整数坐标变换（无透视除法，直接取整数结果）
  Vector3Int multiplyVector3Int(Vector3Int vector) {
    final x =
        vector.x * _values[0] +
        vector.y * _values[4] +
        vector.z * _values[8] +
        1 * _values[12];
    final y =
        vector.x * _values[1] +
        vector.y * _values[5] +
        vector.z * _values[9] +
        1 * _values[13];
    final z =
        vector.x * _values[2] +
        vector.y * _values[6] +
        vector.z * _values[10] +
        1 * _values[14];
    // 整数矩阵通常用于仿射变换（无透视），故不做除法
    return Vector3Int(x, y, z);
  }

  /// 转置矩阵（行和列互换）
  MatrixInt transpose() {
    final result = MatrixInt.zero();
    for (int col = 0; col < 4; col++) {
      for (int row = 0; row < 4; row++) {
        result.setColumnRow(row, col, getColumnRow(col, row));
      }
    }
    return result;
  }

  // -------------------------- 常用变换矩阵 --------------------------
  /// 生成整数平移矩阵（基于三维整数偏移量）
  static MatrixInt translation(Vector3Int offset) {
    final mat = MatrixInt.identity();
    mat.setColumnRow(3, 0, offset.x); // 平移X
    mat.setColumnRow(3, 1, offset.y); // 平移Y
    mat.setColumnRow(3, 2, offset.z); // 平移Z
    return mat;
  }

  /// 生成整数缩放矩阵（基于三维整数缩放因子）
  static MatrixInt scaling(Vector3Int scale) {
    final mat = MatrixInt.identity();
    mat.setColumnRow(0, 0, scale.x); // X轴缩放
    mat.setColumnRow(1, 1, scale.y); // Y轴缩放
    mat.setColumnRow(2, 2, scale.z); // Z轴缩放
    return mat;
  }

  Vector4Int multiplyVector4Int(Vector4Int v) {
    final x =
        v.x * _values[0] +
        v.y * _values[4] +
        v.z * _values[8] +
        v.w * _values[12];
    final y =
        v.x * _values[1] +
        v.y * _values[5] +
        v.z * _values[9] +
        v.w * _values[13];
    final z =
        v.x * _values[2] +
        v.y * _values[6] +
        v.z * _values[10] +
        v.w * _values[14];
    final w =
        v.x * _values[3] +
        v.y * _values[7] +
        v.z * _values[11] +
        v.w * _values[15];
    return Vector4Int(x, y, z, w);
  }

  // -------------------------- 工具方法 --------------------------
  /// 转换为浮点矩阵（用于需要浮点运算的场景）
  Matrix toMatrix() {
    return Matrix.fromList(_values.map((v) => v.toDouble()).toList());
  }
}
