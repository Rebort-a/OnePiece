import 'dart:math' as math;
import 'dart:ui';

import 'constant.dart';

// 三维向量
class Vector3 {
  final double x, y, z;

  const Vector3(this.x, this.y, this.z);

  static const Vector3 zero = Vector3(0, 0, 0);
  // factory Vector3.zero() => const Vector3(0, 0, 0);
  // const Vector3.zero() : x = 0, y = 0, z = 0;
  static const Vector3 one = Vector3(1, 1, 1);
  static const Vector3 right = Vector3(1, 0, 0); // 右方向（x轴）
  static const Vector3 up = Vector3(0, 1, 0); // 上方向（y轴）
  static const Vector3 forward = Vector3(0, 0, 1); // 前方向（z轴）

  // 向量运算符
  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 operator *(double scalar) =>
      Vector3(x * scalar, y * scalar, z * scalar);
  Vector3 operator /(double scalar) =>
      Vector3(x / scalar, y / scalar, z / scalar);
  Vector3 operator -() => Vector3(-x, -y, -z);

  // 向量模长
  double get magnitude => math.sqrt(x * x + y * y + z * z);
  // 向量归一化，单位向量
  Vector3 get normalized =>
      magnitude > Constant.epsilon ? this / magnitude : Vector3.zero;

  // 计算与另一个向量的距离（模长差）
  double distanceTo(Vector3 other) => (this - other).magnitude;

  //向量点积，用来计算夹角
  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;

  //向量叉积，用来计算法线
  Vector3 cross(Vector3 other) => Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  Vector3 rotateX(double angle) {
    final cosAngle = math.cos(angle);
    final sinAngle = math.sin(angle);
    return Vector3(x, y * cosAngle - z * sinAngle, y * sinAngle + z * cosAngle);
  }

  Vector3 rotateY(double angle) {
    final cosAngle = math.cos(angle);
    final sinAngle = math.sin(angle);
    return Vector3(
      x * cosAngle + z * sinAngle,
      y,
      -x * sinAngle + z * cosAngle,
    );
  }

  Vector3 rotateZ(double angle) {
    final cosAngle = math.cos(angle);
    final sinAngle = math.sin(angle);
    return Vector3(x * cosAngle - y * sinAngle, x * sinAngle + y * cosAngle, z);
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
  // 获取碰撞体类型
  ColliderType get type;
  // 检查和其他碰撞体碰撞
  bool checkCollision(Collider other);
  // 检查和点碰撞
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

  // 获取碰撞体的边界
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

  // 获取方块颜色
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

class CameraView {
  Vector3 position;
  double yaw; // 水平旋转 (弧度)
  double pitch; // 垂直旋转 (弧度)

  CameraView({required this.position, this.yaw = 0, this.pitch = 0});

  CameraView copyWith({Vector3? position, double? yaw, double? pitch}) {
    return CameraView(
      position: position ?? this.position,
      yaw: yaw ?? this.yaw,
      pitch: pitch ?? this.pitch,
    );
  }

  bool equals(CameraView other) {
    return position.equals(other.position) &&
        yaw == other.yaw &&
        pitch == other.pitch;
  }
}

class Player {
  final BoxCollider collider; // 玩家碰撞体
  final CameraView view; // 玩家视野
  Vector3 _position;
  Vector3 velocity;
  bool bottomSupport;

  Player({
    required Vector3 position,
    Vector3? velocity,
    this.bottomSupport = false,
  }) : _position = position,
       velocity = velocity ?? Vector3.zero,
       view = CameraView(position: position),
       collider = BoxCollider(
         position: position,
         size: Vector3(
           Constant.playerWidth,
           Constant.playerHeight,
           Constant.playerWidth,
         ),
       );

  Vector3 get position => _position;

  set position(Vector3 value) {
    // 更新玩家坐标
    _position = value;
    // 更新视野坐标
    view.position = _position;
    // 更新碰撞体坐标
    collider.position = _position;
  }

  double get yaw => view.yaw;
  double get pitch => view.pitch;

  // 获取玩家前方方向向量 (Z轴正方向为前方)
  Vector3 get forward {
    final dir = Vector3(0, 0, 1).rotateY(yaw);
    return Vector3(dir.x, 0, dir.z).normalized;
  }

  // 获取玩家右侧方向向量
  Vector3 get right {
    final dir = Vector3(1, 0, 0).rotateY(yaw);
    return Vector3(dir.x, 0, dir.z).normalized;
  }

  // 获取相机方向向量 (考虑俯仰角)
  Vector3 get cameraDirection {
    return Vector3(0, 0, 1).rotateY(yaw).rotateX(pitch).normalized;
  }

  // 更新玩家状态
  void update(double deltaTime, List<Block> blocks) {
    // 应用重力
    if (!bottomSupport) {
      velocity = velocity + Vector3(0, -Constant.gravity * deltaTime, 0);
    }

    // 限制下落速度
    if (velocity.y < -Constant.maxFallSpeed) {
      velocity = Vector3(velocity.x, -Constant.maxFallSpeed, velocity.z);
    }

    // 保存当前位置用于碰撞检测
    final oldPosition = position;

    // 应用速度更新位置
    position = position + velocity * deltaTime;
    collider.position = position;

    // 检测与方块的碰撞
    bottomSupport = false;
    for (final block in blocks) {
      if (block.penetrable) continue;

      if (collider.checkCollision(block.collider)) {
        _resolveCollision(block.collider, oldPosition);
      }
    }
  }

  // 解析碰撞
  void _resolveCollision(BoxCollider block, Vector3 oldPosition) {
    // 计算穿透深度
    final overlapX = _calculateOverlap(
      collider.minX,
      collider.maxX,
      block.minX,
      block.maxX,
    );
    final overlapY = _calculateOverlap(
      collider.minY,
      collider.maxY,
      block.minY,
      block.maxY,
    );
    final overlapZ = _calculateOverlap(
      collider.minZ,
      collider.maxZ,
      block.minZ,
      block.maxZ,
    );

    // 找出最小穿透方向
    if (overlapX.abs() <= overlapY.abs() && overlapX.abs() <= overlapZ.abs()) {
      // X轴碰撞
      position = Vector3(position.x + overlapX, position.y, position.z);
      velocity = Vector3(0, velocity.y, velocity.z);
    } else if (overlapY.abs() <= overlapX.abs() &&
        overlapY.abs() <= overlapZ.abs()) {
      // Y轴碰撞
      position = Vector3(position.x, position.y + overlapY, position.z);
      if (overlapY > 0) {
        // 从上方碰撞，站在地面上
        bottomSupport = true;
      }
      velocity = Vector3(velocity.x, 0, velocity.z);
    } else {
      // Z轴碰撞
      position = Vector3(position.x, position.y, position.z + overlapZ);
      velocity = Vector3(velocity.x, velocity.y, 0);
    }

    collider.position = position;
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
      velocity = Vector3(velocity.x, Constant.jumpForce, velocity.z);
      bottomSupport = false;
    }
  }

  // 移动
  void move(Vector3 direction, double speed, double deltaTime) {
    final moveVector = direction.normalized * speed * deltaTime;
    velocity = Vector3(moveVector.x, velocity.y, moveVector.z);
  }

  // 旋转视角
  void rotate(double deltaYaw, double deltaPitch) {
    view.yaw += deltaYaw;
    view.pitch += deltaPitch;

    // 限制俯仰角范围
    view.pitch = view.pitch.clamp(
      -Constant.pitchLimit * math.pi,
      Constant.pitchLimit * math.pi,
    );
  }
}
