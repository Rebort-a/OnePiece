import 'dart:math' as math;

/// 向量模板接口
abstract class Vector<T> {
  static const double epsilon = 1e-5;
  T operator +(T other);
  T operator -(T other);
  T operator *(double scalar);
  T operator /(double scalar);
  T operator -();

  double get magnitude;
  double get magnitudeSquare;
  T get normalized;

  double dot(T other);

  bool get isZero;

  @override
  String toString();
  @override
  bool operator ==(Object other);
  @override
  int get hashCode;
}

/// 二维向量
class Vector2 implements Vector<Vector2> {
  final double x, y;

  const Vector2(this.x, this.y);
  static const Vector2 zero = Vector2(0, 0);

  Vector2 appointX(double newX) => Vector2(newX, y);
  Vector2 appointY(double newY) => Vector2(x, newY);

  @override
  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);

  @override
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);

  @override
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);

  @override
  Vector2 operator /(double scalar) => Vector2(x / scalar, y / scalar);

  @override
  Vector2 operator -() => Vector2(-x, -y);

  @override
  double get magnitudeSquare => x * x + y * y;

  @override
  double get magnitude => math.sqrt(magnitudeSquare);

  @override
  Vector2 get normalized =>
      magnitude > Vector.epsilon ? this / magnitude : Vector2.zero;

  @override
  double dot(Vector2 other) => x * other.x + y * other.y;

  @override
  bool get isZero => x.abs() < Vector.epsilon && y.abs() < Vector.epsilon;

  @override
  String toString() => 'Vector2($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector2 &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < Vector.epsilon &&
          (y - other.y).abs() < Vector.epsilon;

  @override
  int get hashCode => Object.hash(x, y);
}

/// 单位二维向量 - 始终保持长度为1
class UnitVector2 extends Vector2 {
  // 私有构造函数，确保只能通过工厂方法创建
  const UnitVector2._(super.x, super.y);

  // 从分量创建单位向量，自动进行单位化
  factory UnitVector2(double x, double y) {
    final vector = Vector2(x, y);
    if (vector.magnitude < Vector.epsilon) {
      return UnitVector2.up;
    }
    final normalized = vector.normalized;
    return UnitVector2._(normalized.x, normalized.y);
  }

  factory UnitVector2.fromAngle(double angle) {
    return UnitVector2(math.cos(angle), math.sin(angle));
  }

  // 从现有Vector2创建单位向量
  factory UnitVector2.fromVector2(Vector2 vector) {
    return UnitVector2(vector.x, vector.y);
  }

  // 预定义的单位向量
  static const UnitVector2 right = UnitVector2._(1, 0);
  static const UnitVector2 left = UnitVector2._(-1, 0);
  static const UnitVector2 up = UnitVector2._(0, 1);
  static const UnitVector2 down = UnitVector2._(0, -1);

  // 重写修改分量的方法
  @override
  UnitVector2 appointX(double newX) {
    return UnitVector2(newX, y);
  }

  @override
  UnitVector2 appointY(double newY) {
    return UnitVector2(x, newY);
  }

  // 重写模长，始终返回1
  @override
  double get magnitude => 1.0;

  // 重写模长平方，始终返回1
  @override
  double get magnitudeSquare => 1.0;

  // 重写单位化方法，返回自身
  @override
  UnitVector2 get normalized => this;

  // 确保不能是零向量
  @override
  bool get isZero => false;

  @override
  String toString() => 'UnitVector2($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnitVector2 &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < Vector.epsilon &&
          (y - other.y).abs() < Vector.epsilon;

  @override
  int get hashCode => Object.hash(x, y);
}

/// 三维向量
class Vector3 implements Vector<Vector3> {
  final double x, y, z;

  const Vector3(this.x, this.y, this.z);

  factory Vector3.all(double value) => Vector3(value, value, value);

  static const Vector3 zero = Vector3(0, 0, 0);
  static const Vector3 one = Vector3(1, 1, 1);
  static const Vector3 up = Vector3(0, 1, 0);

  Vector3 appointX(double newX) => Vector3(newX, y, z);
  Vector3 appointY(double newY) => Vector3(x, newY, z);
  Vector3 appointZ(double newZ) => Vector3(x, y, newZ);

  @override
  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);

  @override
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);

  @override
  Vector3 operator *(double scalar) =>
      Vector3(x * scalar, y * scalar, z * scalar);

  @override
  Vector3 operator /(double scalar) =>
      Vector3(x / scalar, y / scalar, z / scalar);

  @override
  Vector3 operator -() => Vector3(-x, -y, -z);

  @override
  double get magnitudeSquare => x * x + y * y + z * z;

  @override
  double get magnitude => math.sqrt(magnitudeSquare);

  @override
  Vector3 get normalized =>
      magnitude > Vector.epsilon ? this / magnitude : Vector3.zero;

  @override
  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;

  Vector3 cross(Vector3 other) => Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  // 对于单位向量UnitVector2 vec，假如其代表二维平面的旋转角度double angle
  // vec.x相当于math.cos(angle)，vec.y相当于math.sin(angle)
  // 如此便可以使用二维单位向量进行三维向量的旋转
  Vector3 rotateAroundX(UnitVector2 vec) {
    return Vector3(x, y * vec.x - z * vec.y, y * vec.y + z * vec.x);
  }

  Vector3 rotateAroundY(UnitVector2 vec) {
    return Vector3(x * vec.x + z * vec.y, y, -x * vec.y + z * vec.x);
  }

  Vector3 rotateAroundZ(UnitVector2 vec) {
    return Vector3(x * vec.x - y * vec.y, x * vec.y + y * vec.x, z);
  }

  @override
  bool get isZero =>
      x.abs() < Vector.epsilon &&
      y.abs() < Vector.epsilon &&
      z.abs() < Vector.epsilon;

  @override
  String toString() => 'Vector3($x, $y, $z)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector3 &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < Vector.epsilon &&
          (y - other.y).abs() < Vector.epsilon &&
          (z - other.z).abs() < Vector.epsilon;

  @override
  int get hashCode => Object.hash(x, y, z);
}

/// 单位三维向量 - 始终保持长度为1
class Vector3Unit extends Vector3 {
  // 私有构造函数，确保只能通过工厂方法创建
  const Vector3Unit._(super.x, super.y, super.z);

  // 从分量创建单位向量，自动进行单位化
  factory Vector3Unit(double x, double y, double z) {
    final vector = Vector3(x, y, z);
    if (vector.magnitude < Vector.epsilon) {
      return Vector3Unit.forward;
    }
    final normalized = vector.normalized;
    return Vector3Unit._(normalized.x, normalized.y, normalized.z);
  }

  // 从现有Vector3创建单位向量
  factory Vector3Unit.fromVector3(Vector3 vector) {
    return Vector3Unit(vector.x, vector.y, vector.z);
  }

  // 预定义的单位向量
  static const Vector3Unit forward = Vector3Unit._(0, 0, 1);
  static const Vector3Unit up = Vector3Unit._(0, 1, 0);
  static const Vector3Unit right = Vector3Unit._(1, 0, 0);

  // 重写修改分量的方法
  @override
  Vector3Unit appointX(double newX) {
    return Vector3Unit(newX, y, z);
  }

  @override
  Vector3Unit appointY(double newY) {
    return Vector3Unit(x, newY, z);
  }

  @override
  Vector3Unit appointZ(double newZ) {
    return Vector3Unit(x, y, newZ);
  }

  // 重写模长，始终返回1
  @override
  double get magnitude => 1.0;

  // 重写模长平方，始终返回1
  @override
  double get magnitudeSquare => 1.0;

  // 重写单位化方法，返回自身
  @override
  Vector3Unit get normalized => this;

  // 确保不能创建零向量
  @override
  bool get isZero => false;

  @override
  String toString() => 'Vector3Unit($x, $y, $z)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector3Unit &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < Vector.epsilon &&
          (y - other.y).abs() < Vector.epsilon &&
          (z - other.z).abs() < Vector.epsilon;

  @override
  int get hashCode => Object.hash(x, y, z);
}

/// 三维整数向量
class Vector3Int {
  final int x, y, z;

  const Vector3Int(this.x, this.y, this.z);

  factory Vector3Int.all(int value) => Vector3Int(value, value, value);

  // 常用静态向量常量
  static const Vector3Int zero = Vector3Int(0, 0, 0);
  static const Vector3Int one = Vector3Int(1, 1, 1);
  static const Vector3Int right = Vector3Int(1, 0, 0);
  static const Vector3Int left = Vector3Int(-1, 0, 0);
  static const Vector3Int up = Vector3Int(0, 1, 0);
  static const Vector3Int down = Vector3Int(0, -1, 0);
  static const Vector3Int forward = Vector3Int(0, 0, 1);
  static const Vector3Int backward = Vector3Int(0, 0, -1);

  // 修改单个分量并返回新向量
  Vector3Int appointX(int newX) => Vector3Int(newX, y, z);
  Vector3Int appointY(int newY) => Vector3Int(x, newY, z);
  Vector3Int appointZ(int newZ) => Vector3Int(x, y, newZ);

  // 向量运算运算符重载
  Vector3Int operator +(Vector3Int other) =>
      Vector3Int(x + other.x, y + other.y, z + other.z);

  Vector3Int operator -(Vector3Int other) =>
      Vector3Int(x - other.x, y - other.y, z - other.z);

  Vector3Int operator *(int scalar) =>
      Vector3Int(x * scalar, y * scalar, z * scalar);

  Vector3Int operator ~/(int scalar) =>
      Vector3Int(x ~/ scalar, y ~/ scalar, z ~/ scalar);

  Vector3Int operator -() => Vector3Int(-x, -y, -z);

  int get magnitudeSquare => x * x + y * y + z * z;

  double get magnitude => math.sqrt(magnitudeSquare);

  Vector3 get normalized {
    final mag = magnitude;
    return mag > Vector.epsilon
        ? Vector3(x / mag, y / mag, z / mag)
        : Vector3.zero;
  }

  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;

  Vector3 cross(Vector3 other) => Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  // 转换为浮点向量
  Vector3 toVector3() => Vector3(x.toDouble(), y.toDouble(), z.toDouble());

  bool get isZero => x == 0 && y == 0 && z == 0;

  @override
  String toString() => 'Vector3Int($x, $y, $z)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector3Int &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);
}

/// 四维向量
class Vector4 implements Vector<Vector4> {
  final double x, y, z, w;

  const Vector4(this.x, this.y, this.z, this.w);

  static const Vector4 zero = Vector4(0, 0, 0, 0);

  Vector4 appointX(double newX) => Vector4(newX, y, z, w);
  Vector4 appointY(double newY) => Vector4(x, newY, z, w);
  Vector4 appointZ(double newZ) => Vector4(x, y, newZ, w);
  Vector4 appointW(double newW) => Vector4(x, y, z, newW);

  @override
  Vector4 operator +(Vector4 other) =>
      Vector4(x + other.x, y + other.y, z + other.z, w + other.w);

  @override
  Vector4 operator -(Vector4 other) =>
      Vector4(x - other.x, y - other.y, z - other.z, w - other.w);

  @override
  Vector4 operator *(double scalar) =>
      Vector4(x * scalar, y * scalar, z * scalar, w * scalar);

  @override
  Vector4 operator /(double scalar) =>
      Vector4(x / scalar, y / scalar, z / scalar, w / scalar);

  @override
  Vector4 operator -() => Vector4(-x, -y, -z, -w);

  @override
  double get magnitudeSquare => x * x + y * y + z * z + w * w;

  @override
  double get magnitude => math.sqrt(magnitudeSquare);

  @override
  Vector4 get normalized =>
      magnitude > Vector.epsilon ? this / magnitude : Vector4.zero;

  @override
  double dot(Vector4 other) =>
      x * other.x + y * other.y + z * other.z + w * other.w;

  @override
  bool get isZero =>
      x.abs() < Vector.epsilon &&
      y.abs() < Vector.epsilon &&
      z.abs() < Vector.epsilon &&
      w.abs() < Vector.epsilon;

  @override
  String toString() => 'Vector4($x, $y, $z, $w)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector4 &&
          runtimeType == other.runtimeType &&
          (x - other.x).abs() < Vector.epsilon &&
          (y - other.y).abs() < Vector.epsilon &&
          (z - other.z).abs() < Vector.epsilon &&
          (w - other.w).abs() < Vector.epsilon;

  @override
  int get hashCode => Object.hash(x, y, z, w);
}
