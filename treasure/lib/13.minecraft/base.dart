import 'dart:math';
import 'dart:ui';

class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3(this.x, this.y, this.z);

  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 operator *(double scalar) =>
      Vector3(x * scalar, y * scalar, z * scalar);
  Vector3 operator /(double scalar) =>
      Vector3(x / scalar, y / scalar, z / scalar);

  double get magnitude => sqrt(x * x + y * y + z * z);
  Vector3 get normalized => this / magnitude;

  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;
  Vector3 cross(Vector3 other) => Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  Vector3 rotateX(double angle) {
    final cosAngle = cos(angle);
    final sinAngle = sin(angle);
    return Vector3(x, y * cosAngle - z * sinAngle, y * sinAngle + z * cosAngle);
  }

  Vector3 rotateY(double angle) {
    final cosAngle = cos(angle);
    final sinAngle = sin(angle);
    return Vector3(
      x * cosAngle + z * sinAngle,
      y,
      -x * sinAngle + z * cosAngle,
    );
  }

  bool equals(Vector3 other, [double epsilon = 0.001]) {
    return (x - other.x).abs() < epsilon &&
        (y - other.y).abs() < epsilon &&
        (z - other.z).abs() < epsilon;
  }
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

  BoxCollider(this.position, this.size);

  @override
  ColliderType get type => ColliderType.box;

  // 获取碰撞体的边界
  double get minX => position.x - size.x / 2;
  double get maxX => position.x + size.x / 2;
  double get minY => position.y - size.y / 2;
  double get maxY => position.y + size.y / 2;
  double get minZ => position.z - size.z / 2;
  double get maxZ => position.z + size.z / 2;

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
  final bool isSolid;

  Block(this.position, this.type)
    : collider = BoxCollider(position, Vector3(1, 1, 1)),
      isSolid = type != BlockType.air;

  // 获取方块颜色
  Color get color {
    switch (type) {
      case BlockType.grass:
        return Color(0xFF4CAF50);
      case BlockType.dirt:
        return Color(0xFF8D6E63);
      case BlockType.stone:
        return Color(0xFF9E9E9E);
      case BlockType.wood:
        return Color(0xFFFF9800);
      case BlockType.glass:
        return Color(0x88FFFFFF);
      default:
        return Color(0x00000000);
    }
  }
}

class Player {
  Vector3 position;
  double yaw; // 水平旋转 (弧度)
  double pitch; // 垂直旋转 (弧度)
  Vector3 velocity;
  bool isOnGround;
  final BoxCollider collider;

  Player({
    required this.position,
    this.yaw = 0,
    this.pitch = 0,
    Vector3? velocity,
    this.isOnGround = false,
  }) : velocity = velocity ?? Vector3(0, 0, 0),
       collider = BoxCollider(position, Vector3(0.6, 1.8, 0.6));

  // 获取玩家前方方向向量
  Vector3 get forward {
    final dir = Vector3(0, 0, -1).rotateY(yaw).rotateX(pitch);
    return Vector3(dir.x, 0, dir.z).normalized;
  }

  // 获取玩家右侧方向向量
  Vector3 get right {
    final dir = Vector3(1, 0, 0).rotateY(yaw);
    return Vector3(dir.x, 0, dir.z).normalized;
  }

  // 更新玩家状态
  void update(double deltaTime, List<Block> blocks) {
    // 应用重力
    velocity = velocity + Vector3(0, -9.8 * deltaTime, 0);

    // 限制下落速度
    if (velocity.y < -20) {
      velocity = Vector3(velocity.x, -20, velocity.z);
    }

    // 保存当前位置用于碰撞检测
    final oldPosition = position;

    // 应用速度更新位置
    position = position + velocity * deltaTime;
    collider.position = position;

    // 检测与地面和方块的碰撞
    isOnGround = false;
    for (final block in blocks) {
      if (!block.isSolid) continue;

      if (collider.checkCollision(block.collider)) {
        // 处理Y轴碰撞 (上下)
        if (oldPosition.y <= block.collider.maxY &&
            position.y > block.collider.maxY) {
          position = Vector3(
            position.x,
            block.collider.maxY + collider.size.y / 2,
            position.z,
          );
          velocity = Vector3(velocity.x, 0, velocity.z);
          isOnGround = true;
        } else if (oldPosition.y >= block.collider.minY &&
            position.y < block.collider.minY) {
          position = Vector3(
            position.x,
            block.collider.minY - collider.size.y / 2,
            position.z,
          );
          velocity = Vector3(velocity.x, 0, velocity.z);
        }

        // 处理X轴碰撞 (左右)
        if (oldPosition.x <= block.collider.maxX &&
            position.x > block.collider.maxX) {
          position = Vector3(
            block.collider.maxX + collider.size.x / 2,
            position.y,
            position.z,
          );
          velocity = Vector3(0, velocity.y, velocity.z);
        } else if (oldPosition.x >= block.collider.minX &&
            position.x < block.collider.minX) {
          position = Vector3(
            block.collider.minX - collider.size.x / 2,
            position.y,
            position.z,
          );
          velocity = Vector3(0, velocity.y, velocity.z);
        }

        // 处理Z轴碰撞 (前后)
        if (oldPosition.z <= block.collider.maxZ &&
            position.z > block.collider.maxZ) {
          position = Vector3(
            position.x,
            position.y,
            block.collider.maxZ + collider.size.z / 2,
          );
          velocity = Vector3(velocity.x, velocity.y, 0);
        } else if (oldPosition.z >= block.collider.minZ &&
            position.z < block.collider.minZ) {
          position = Vector3(
            position.x,
            position.y,
            block.collider.minZ - collider.size.z / 2,
          );
          velocity = Vector3(velocity.x, velocity.y, 0);
        }

        // 更新碰撞体位置
        collider.position = position;
      }
    }

    // 简单的地面检测（如果没有方块碰撞，检查Y坐标）
    if (!isOnGround && position.y < 1.8) {
      position = Vector3(position.x, 1.8, position.z);
      velocity = Vector3(velocity.x, 0, velocity.z);
      isOnGround = true;
    }
  }

  // 跳跃
  void jump() {
    if (isOnGround) {
      velocity = Vector3(velocity.x, 5, velocity.z);
      isOnGround = false;
    }
  }

  // 移动
  void move(Vector3 direction, double speed, double deltaTime) {
    final moveVector = direction.normalized * speed * deltaTime;
    velocity = Vector3(moveVector.x, velocity.y, moveVector.z);
  }

  // 旋转视角
  void rotate(double deltaYaw, double deltaPitch) {
    yaw += deltaYaw;
    pitch += deltaPitch;

    // 限制俯仰角范围，防止过度仰头或低头
    pitch = pitch.clamp(-pi * 0.47, pi * 0.47); // 约-85°到85°
  }
}
