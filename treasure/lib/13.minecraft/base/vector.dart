import 'dart:math' as math;

// 数学精度
const double epsilon = 0.001;

/// 二维向量
class Vector2 {
  final double x, y;

  const Vector2(this.x, this.y);
  static const Vector2 zero = Vector2(0, 0);

  Vector2 appointX(double newX) => Vector2(newX, y);
  Vector2 appointY(double newY) => Vector2(x, newY);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);
  Vector2 operator /(double scalar) => Vector2(x / scalar, y / scalar);
  Vector2 operator -() => Vector2(-x, -y);

  double get magnitudeSquare => x * x + y * y;
  double get magnitude => math.sqrt(magnitudeSquare);
  Vector2 get normalized =>
      magnitude > epsilon ? this / magnitude : Vector2.zero;

  double distanceTo(Vector2 other) => (this - other).magnitude;

  double dot(Vector2 other) => x * other.x + y * other.y;

  double cross(Vector2 other) => x * other.y - y * other.x;

  bool get isZero => x.abs() < epsilon && y.abs() < epsilon;
}

/// 单位二维向量 - 始终保持长度为1
class UnitVector2 extends Vector2 {
  // 私有构造函数，确保只能通过工厂方法创建
  const UnitVector2._(super.x, super.y);

  // 从分量创建单位向量，自动进行单位化
  factory UnitVector2(double x, double y) {
    final vector = Vector2(x, y);
    if (vector.magnitude < epsilon) {
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
}

/// 三维向量
class Vector3 {
  final double x, y, z;

  const Vector3(this.x, this.y, this.z);

  factory Vector3.all(double value) => Vector3(value, value, value);

  static const Vector3 zero = Vector3(0, 0, 0);
  static const Vector3 one = Vector3(1, 1, 1);
  static const Vector3 up = Vector3(0, 1, 0);

  Vector3 appointX(double newX) => Vector3(newX, y, z);
  Vector3 appointY(double newY) => Vector3(x, newY, z);
  Vector3 appointZ(double newZ) => Vector3(x, y, newZ);

  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 operator *(double scalar) =>
      Vector3(x * scalar, y * scalar, z * scalar);
  Vector3 operator /(double scalar) =>
      Vector3(x / scalar, y / scalar, z / scalar);
  Vector3 operator -() => Vector3(-x, -y, -z);

  double get magnitudeSquare => x * x + y * y + z * z;
  double get magnitude => math.sqrt(magnitudeSquare);
  Vector3 get normalized =>
      magnitude > epsilon ? this / magnitude : Vector3.zero;

  double distanceTo(Vector3 other) => (this - other).magnitude;
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

  bool equals(Vector3 other, [double epsilon = epsilon]) {
    return (x - other.x).abs() < epsilon &&
        (y - other.y).abs() < epsilon &&
        (z - other.z).abs() < epsilon;
  }

  bool get isZero =>
      x.abs() < epsilon && y.abs() < epsilon && z.abs() < epsilon;

  @override
  String toString() => 'Vector3($x, $y, $z)';
}

/// 单位三维向量 - 始终保持长度为1
class Vector3Unit extends Vector3 {
  // 私有构造函数，确保只能通过工厂方法创建
  const Vector3Unit._(super.x, super.y, super.z);

  // 从分量创建单位向量，自动进行单位化
  factory Vector3Unit(double x, double y, double z) {
    final vector = Vector3(x, y, z);
    if (vector.magnitude < epsilon) {
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

  // 除法运算返回整数向量（会做截断处理）
  Vector3Int operator ~/(int scalar) =>
      Vector3Int(x ~/ scalar, y ~/ scalar, z ~/ scalar);

  Vector3Int operator -() => Vector3Int(-x, -y, -z);

  // 向量属性
  int get magnitudeSquare => x * x + y * y + z * z;
  double get magnitude => math.sqrt(magnitudeSquare);

  // 转换为浮点向量
  Vector3 toVector3() => Vector3(x.toDouble(), y.toDouble(), z.toDouble());

  // 单位化
  Vector3 get normalized {
    final mag = magnitude;
    return mag > epsilon ? Vector3(x / mag, y / mag, z / mag) : Vector3.zero;
  }

  // 向量运算
  double distanceTo(Vector3Int other) => (this - other).magnitude;
  int dot(Vector3Int other) => x * other.x + y * other.y + z * other.z;

  Vector3Int cross(Vector3Int other) => Vector3Int(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  // 相等性判断
  bool equals(Vector3Int other) {
    return x == other.x && y == other.y && z == other.z;
  }

  bool get isZero => x == 0 && y == 0 && z == 0;

  @override
  String toString() => 'Vector3Int($x, $y, $z)';
}

class Vector4 {
  final double x, y, z, w;

  const Vector4(this.x, this.y, this.z, this.w);
}
