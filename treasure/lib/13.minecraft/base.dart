import 'dart:math' as math;
import 'dart:ui';

import 'constant.dart';

// 二维向量
class Vector2 {
  final double x, y;

  const Vector2(this.x, this.y);
  static const Vector2 zero = Vector2(0, 0);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator -(Vector2 other) => Vector2(x - other.x, y - other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);
  Vector2 operator /(double scalar) => Vector2(x / scalar, y / scalar);
  Vector2 operator -() => Vector2(-x, -y);

  double get magnitude => math.sqrt(x * x + y * y);
  Vector2 get normalized =>
      magnitude > Constant.epsilon ? this / magnitude : Vector2.zero;

  double dot(Vector2 other) => x * other.x + y * other.y;

  bool get isZero => x.abs() < Constant.epsilon && y.abs() < Constant.epsilon;

  Vector2 appointX(double newX) {
    return Vector2(newX, y);
  }

  Vector2 appointY(double newY) {
    return Vector2(x, newY);
  }

  @override
  String toString() => 'Vector2($x, $y)';
}

// 三维向量
class Vector3 {
  final double x, y, z;

  const Vector3(this.x, this.y, this.z);

  static const Vector3 zero = Vector3(0, 0, 0);
  static const Vector3 one = Vector3(1, 1, 1);
  static const Vector3 forward = Vector3(0, 0, 1);
  static const Vector3 up = Vector3(0, 1, 0);
  static const Vector3 right = Vector3(1, 0, 0);

  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 operator *(double scalar) =>
      Vector3(x * scalar, y * scalar, z * scalar);
  Vector3 operator /(double scalar) =>
      Vector3(x / scalar, y / scalar, z / scalar);
  Vector3 operator -() => Vector3(-x, -y, -z);

  double get magnitude => math.sqrt(x * x + y * y + z * z);
  Vector3 get normalized =>
      magnitude > Constant.epsilon ? this / magnitude : Vector3.zero;

  double distanceTo(Vector3 other) => (this - other).magnitude;
  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;

  Vector3 cross(Vector3 other) => Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  Vector3 rotateX(Vector2 vec) {
    return Vector3(x, y * vec.x - z * vec.y, y * vec.y + z * vec.x);
  }

  Vector3 rotateY(Vector2 vec) {
    return Vector3(x * vec.x + z * vec.y, y, -x * vec.y + z * vec.x);
  }

  Vector3 rotateZ(Vector2 vec) {
    return Vector3(x * vec.x - y * vec.y, x * vec.y + y * vec.x, z);
  }

  bool equals(Vector3 other, [double epsilon = Constant.epsilon]) {
    return (x - other.x).abs() < epsilon &&
        (y - other.y).abs() < epsilon &&
        (z - other.z).abs() < epsilon;
  }

  bool get isZero =>
      x.abs() < Constant.epsilon &&
      y.abs() < Constant.epsilon &&
      z.abs() < Constant.epsilon;

  @override
  String toString() => 'Vector3($x, $y, $z)';
}

// 碰撞体类型
enum ColliderType { box, sphere }

// 碰撞体接口
abstract class Collider {
  ColliderType get type;
  bool checkCollision(Collider other);
  bool containsPoint(Vector3 point);
}

// 方块碰撞体
class BoxCollider implements Collider {
  Vector3 position;
  final Vector3 size;
  final Vector3 _halfSize;

  BoxCollider({required this.position, required this.size})
    : _halfSize = size * 0.5;

  @override
  ColliderType get type => ColliderType.box;

  double get minX => position.x - _halfSize.x;
  double get maxX => position.x + _halfSize.x;
  double get minY => position.y - _halfSize.y;
  double get maxY => position.y + _halfSize.y;
  double get minZ => position.z - _halfSize.z;
  double get maxZ => position.z + _halfSize.z;

  @override
  bool checkCollision(Collider other) {
    if (other is BoxCollider) {
      return (minX <= other.maxX && maxX >= other.minX) &&
          (minY <= other.maxY && maxY >= other.minY) &&
          (minZ <= other.maxZ && maxZ >= other.minZ);
    }
    return false;
  }

  @override
  bool containsPoint(Vector3 point) {
    return point.x >= minX &&
        point.x <= maxX &&
        point.y >= minY &&
        point.y <= maxY &&
        point.z >= minZ &&
        point.z <= maxZ;
  }
}

// 方块类型
enum BlockType { grass, dirt, stone, wood, glass, air }

// 游戏方块类
class Block {
  final Vector3 position;
  final BlockType type;
  final BoxCollider collider;

  Block(this.position, this.type)
    : collider = BoxCollider(position: position, size: Vector3(1, 1, 1));

  bool get penetrable => type == BlockType.air;

  Color get color {
    switch (type) {
      case BlockType.grass:
        return const Color(0xFF4CAF50);
      case BlockType.dirt:
        return const Color(0xFF8D6E63);
      case BlockType.stone:
        return const Color(0xFF9E9E9E);
      case BlockType.wood:
        return const Color(0xFFFF9800);
      case BlockType.glass:
        return const Color(0x88FFFFFF);
      default:
        return const Color(0x00000000);
    }
  }
}

class Player extends BoxCollider {
  Vector3 orientation; // 朝向
  Vector3 velocity; // 速度
  bool bottomSupport; // 底部是否有支撑

  Player({required super.position})
    : orientation = Vector3.forward.normalized,
      velocity = Vector3.zero,
      bottomSupport = false,
      super(
        size: Vector3(
          Constant.playerWidth,
          Constant.playerHeight,
          Constant.playerWidth,
        ),
      );

  Vector2 get forwardUnit {
    return Vector2(orientation.x, orientation.z).normalized;
  }

  Vector2 get rightUnit {
    return Vector2(orientation.z, -orientation.x).normalized;
  }

  double get pitchSin {
    return -orientation.y;
  }

  // 更新玩家状态
  void update(double deltaTime, List<Block> blocks) {
    // 应用重力
    if (!bottomSupport) {
      velocity = Vector3(
        velocity.x,
        velocity.y - Constant.gravity * deltaTime,
        velocity.z,
      );
    }

    // 限制下落速度
    if (velocity.y < -Constant.maxFallSpeed) {
      velocity = Vector3(velocity.x, -Constant.maxFallSpeed, velocity.z);
    }

    // 保存当前位置用于碰撞检测
    final oldPosition = position;

    // 应用速度更新位置
    position += velocity * deltaTime;

    // 检测与方块的碰撞
    bottomSupport = false;
    for (final block in blocks) {
      if (block.penetrable) continue;

      if (checkCollision(block.collider)) {
        _resolveCollision(block.collider, oldPosition);
      }
    }
  }

  // 解析碰撞
  void _resolveCollision(BoxCollider block, Vector3 oldPosition) {
    final overlapX = _calculateOverlap(minX, maxX, block.minX, block.maxX);
    final overlapY = _calculateOverlap(minY, maxY, block.minY, block.maxY);
    final overlapZ = _calculateOverlap(minZ, maxZ, block.minZ, block.maxZ);

    if (overlapX.abs() <= overlapY.abs() && overlapX.abs() <= overlapZ.abs()) {
      position = Vector3(position.x + overlapX, position.y, position.z);
      velocity = Vector3(0, velocity.y, velocity.z);
    } else if (overlapY.abs() <= overlapX.abs() &&
        overlapY.abs() <= overlapZ.abs()) {
      position = Vector3(position.x, position.y + overlapY, position.z);
      if (overlapY > 0) {
        bottomSupport = true;
      }
      velocity = Vector3(velocity.x, 0, velocity.z);
    } else {
      position = Vector3(position.x, position.y, position.z + overlapZ);
      velocity = Vector3(velocity.x, velocity.y, 0);
    }
  }

  double _calculateOverlap(double min1, double max1, double min2, double max2) {
    if (max1 <= min2 || min1 >= max2) return 0;
    final overlap1 = max1 - min2;
    final overlap2 = max2 - min1;
    return overlap1 < overlap2 ? -overlap1 : overlap2;
  }

  // 跳跃
  void jump() {
    if (bottomSupport) {
      bottomSupport = false;
      velocity = Vector3(velocity.x, Constant.jumpStrength, velocity.z);
    }
  }

  // 移动
  void move(Vector2 input, double speed) {
    if (input.isZero) return;

    final Vector2 moveDirection =
        (rightUnit * input.x + forwardUnit * input.y).normalized;
    velocity = Vector3(
      moveDirection.x * speed,
      velocity.y,
      moveDirection.y * speed,
    );
  }

  // 旋转视角
  void rotateView(double deltaYaw, double deltaPitch) {
    final direction = orientation.normalized;

    final currentYaw = math.atan2(direction.x, direction.z);
    final currentPitch = -math.asin(direction.y.clamp(-1.0, 1.0));

    final newYaw = currentYaw + deltaYaw;
    final newPitch = (currentPitch - deltaPitch).clamp(
      -Constant.pitchLimit,
      Constant.pitchLimit,
    );

    orientation = Vector3(
      math.sin(newYaw) * math.cos(newPitch),
      -math.sin(newPitch),
      math.cos(newYaw) * math.cos(newPitch),
    ).normalized;
  }
}

// 裁剪平面
class ClipPlane {
  final Vector3 normal;
  final double distance;

  ClipPlane(this.normal, this.distance);

  // 判断点是否在平面内（法线指向可见区域）
  bool isInside(Vector3 point) {
    return point.dot(normal) >= distance;
  }

  // 计算线段与平面的交点
  Vector3? intersectLine(Vector3 start, Vector3 end) {
    final startDist = start.dot(normal) - distance;
    final endDist = end.dot(normal) - distance;

    if (startDist >= 0 && endDist >= 0) return null; // 都在内部
    if (startDist < 0 && endDist < 0) return null; // 都在外部

    final t = startDist / (startDist - endDist);
    return start + (end - start) * t;
  }
}

// 视锥体
class Frustum {
  final List<ClipPlane> planes;

  Frustum()
    : planes = [
        ClipPlane(Vector3(0, 0, 1), Constant.nearClip), // 近平面
        ClipPlane(Vector3(0, 0, -1), -Constant.farClip), // 远平面
      ];

  // 扩展：添加左右上下平面（基于视野角度）
  void updateWithView(Vector3 forward, Vector3 right, Vector3 up) {
    final fovRad = Constant.fieldOfView * 3.14159 / 180.0;
    final tanHalfFov = math.tan(fovRad * 0.5);

    // 左右平面
    final rightPlaneNormal = (forward - right * tanHalfFov).normalized;
    final leftPlaneNormal = (forward + right * tanHalfFov).normalized;

    // 上下平面
    final topPlaneNormal = (forward - up * tanHalfFov).normalized;
    final bottomPlaneNormal = (forward + up * tanHalfFov).normalized;

    planes.addAll([
      ClipPlane(rightPlaneNormal, 0), // 右平面
      ClipPlane(leftPlaneNormal, 0), // 左平面
      ClipPlane(topPlaneNormal, 0), // 上平面
      ClipPlane(bottomPlaneNormal, 0), // 下平面
    ]);
  }

  // 判断点是否在视锥体内
  bool containsPoint(Vector3 point) {
    for (final plane in planes) {
      if (!plane.isInside(point)) return false;
    }
    return true;
  }

  // 裁剪多边形
  List<Vector3> clipPolygon(List<Vector3> polygon, ClipPlane plane) {
    if (polygon.length < 3) return [];

    final output = <Vector3>[];
    Vector3 prevPoint = polygon.last;
    bool prevInside = plane.isInside(prevPoint);

    for (final currentPoint in polygon) {
      final currentInside = plane.isInside(currentPoint);

      if (currentInside) {
        if (!prevInside) {
          // 从外部进入内部，添加交点
          final intersection = plane.intersectLine(prevPoint, currentPoint);
          if (intersection != null) {
            output.add(intersection);
          }
        }
        output.add(currentPoint);
      } else if (prevInside) {
        // 从内部进入外部，添加交点
        final intersection = plane.intersectLine(prevPoint, currentPoint);
        if (intersection != null) {
          output.add(intersection);
        }
      }

      prevPoint = currentPoint;
      prevInside = currentInside;
    }

    return output;
  }
}
