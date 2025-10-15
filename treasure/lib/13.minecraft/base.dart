import 'dart:math' as math;
import 'dart:ui';

import 'constant.dart';

/// 二维向量
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
      magnitude > Constants.epsilon ? this / magnitude : Vector2.zero;

  double dot(Vector2 other) => x * other.x + y * other.y;

  bool get isZero => x.abs() < Constants.epsilon && y.abs() < Constants.epsilon;

  Vector2 appointX(double newX) => Vector2(newX, y);
  Vector2 appointY(double newY) => Vector2(x, newY);

  @override
  String toString() => 'Vector2($x, $y)';
}

/// 三维向量
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
      magnitude > Constants.epsilon ? this / magnitude : Vector3.zero;

  double distanceTo(Vector3 other) => (this - other).magnitude;
  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;

  Vector3 cross(Vector3 other) => Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  bool equals(Vector3 other, [double epsilon = Constants.epsilon]) {
    return (x - other.x).abs() < epsilon &&
        (y - other.y).abs() < epsilon &&
        (z - other.z).abs() < epsilon;
  }

  bool get isZero =>
      x.abs() < Constants.epsilon &&
      y.abs() < Constants.epsilon &&
      z.abs() < Constants.epsilon;

  Vector3 appointX(double newX) => Vector3(newX, y, z);
  Vector3 appointY(double newY) => Vector3(x, newY, z);
  Vector3 appointZ(double newZ) => Vector3(x, y, newZ);

  @override
  String toString() => 'Vector3($x, $y, $z)';
}

/// 轴对齐包围盒
class AABB {
  final Vector3 min, max;

  AABB(this.min, this.max);

  /// 检查与另一AABB是否相交
  bool intersects(AABB other) =>
      min.x <= other.max.x &&
      max.x >= other.min.x &&
      min.y <= other.max.y &&
      max.y >= other.min.y &&
      min.z <= other.max.z &&
      max.z >= other.min.z;

  /// 检查是否包含某点
  bool contains(Vector3 point) =>
      point.x >= min.x &&
      point.x <= max.x &&
      point.y >= min.y &&
      point.y <= max.y &&
      point.z >= min.z &&
      point.z <= max.z;

  /// 获取中心点
  Vector3 get center => Vector3(
    (min.x + max.x) * 0.5,
    (min.y + max.y) * 0.5,
    (min.z + max.z) * 0.5,
  );

  /// 将包围盒分割为8个子盒（用于八叉树）
  List<AABB> split() {
    final center = this.center;
    return [
      AABB(Vector3(min.x, min.y, min.z), Vector3(center.x, center.y, center.z)),
      AABB(Vector3(center.x, min.y, min.z), Vector3(max.x, center.y, center.z)),
      AABB(Vector3(min.x, center.y, min.z), Vector3(center.x, max.y, center.z)),
      AABB(Vector3(center.x, center.y, min.z), Vector3(max.x, max.y, center.z)),
      AABB(Vector3(min.x, min.y, center.z), Vector3(center.x, center.y, max.z)),
      AABB(Vector3(center.x, min.y, center.z), Vector3(max.x, center.y, max.z)),
      AABB(Vector3(min.x, center.y, center.z), Vector3(center.x, max.y, max.z)),
      AABB(Vector3(center.x, center.y, center.z), Vector3(max.x, max.y, max.z)),
    ];
  }
}

/// 碰撞体类型
enum ColliderType { box, sphere }

/// 碰撞体接口
abstract class Collider {
  ColliderType get type;
  Vector3 get position;
  bool checkCollision(Collider other);
  bool containsPoint(Vector3 point);
}

/// 方块碰撞体
class BoxCollider implements Collider {
  @override
  Vector3 position;
  final Vector3 size;
  final Vector3 _halfSize;

  BoxCollider({required this.position, required this.size})
    : _halfSize = size * 0.5;

  @override
  ColliderType get type => ColliderType.box;

  // 边界计算
  double get minX => position.x - _halfSize.x;
  double get maxX => position.x + _halfSize.x;
  double get minY => position.y - _halfSize.y;
  double get maxY => position.y + _halfSize.y;
  double get minZ => position.z - _halfSize.z;
  double get maxZ => position.z + _halfSize.z;

  @override
  bool checkCollision(Collider other) {
    if (other is! BoxCollider) return false;

    return (minX <= other.maxX && maxX >= other.minX) &&
        (minY <= other.maxY && maxY >= other.minY) &&
        (minZ <= other.maxZ && maxZ >= other.minZ);
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

  /// 计算与另一包围盒的重叠量
  double _calculateOverlap(double min1, double max1, double min2, double max2) {
    if (max1 <= min2 || min1 >= max2) return 0;
    final overlap1 = max1 - min2;
    final overlap2 = max2 - min1;
    return overlap1 < overlap2 ? -overlap1 : overlap2;
  }

  /// 解析与另一碰撞体的碰撞
  Vector3 resolveCollision(BoxCollider other, Vector3 oldPosition) {
    final overlapX = _calculateOverlap(minX, maxX, other.minX, other.maxX);
    final overlapY = _calculateOverlap(minY, maxY, other.minY, other.maxY);
    final overlapZ = _calculateOverlap(minZ, maxZ, other.minZ, other.maxZ);

    // 选择最小重叠方向进行解析
    if (overlapX.abs() <= overlapY.abs() && overlapX.abs() <= overlapZ.abs()) {
      return Vector3(overlapX, 0, 0);
    } else if (overlapY.abs() <= overlapX.abs() &&
        overlapY.abs() <= overlapZ.abs()) {
      return Vector3(0, overlapY, 0);
    } else {
      return Vector3(0, 0, overlapZ);
    }
  }
}

/// 方块类型
enum BlockType { grass, dirt, stone, wood, glass, air }

/// 游戏方块
class Block {
  final Vector3 position;
  final BlockType type;
  final BoxCollider collider;

  Block(this.position, this.type)
    : collider = BoxCollider(position: position, size: Vector3.one);

  /// 是否可穿透
  bool get penetrable => type == BlockType.air;

  /// 获取方块颜色
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

  /// 获取方块顶点
  List<Vector3> get vertices => [
    Vector3(position.x - 0.5, position.y - 0.5, position.z - 0.5),
    Vector3(position.x + 0.5, position.y - 0.5, position.z - 0.5),
    Vector3(position.x + 0.5, position.y + 0.5, position.z - 0.5),
    Vector3(position.x - 0.5, position.y + 0.5, position.z - 0.5),
    Vector3(position.x - 0.5, position.y - 0.5, position.z + 0.5),
    Vector3(position.x + 0.5, position.y - 0.5, position.z + 0.5),
    Vector3(position.x + 0.5, position.y + 0.5, position.z + 0.5),
    Vector3(position.x - 0.5, position.y + 0.5, position.z + 0.5),
  ];
}

/// 玩家角色
class Player extends BoxCollider {
  Vector3 orientation; // 朝向
  Vector3 velocity; // 速度
  bool isGrounded; // 是否在地面上

  Player({required super.position})
    : orientation = Vector3.forward.normalized,
      velocity = Vector3.zero,
      isGrounded = false,
      super(
        size: Vector3(
          Constants.playerWidth,
          Constants.playerHeight,
          Constants.playerWidth,
        ),
      );

  /// 获取前向单位向量（2D）
  Vector2 get forwardUnit => Vector2(orientation.x, orientation.z).normalized;

  /// 获取右向单位向量（2D）
  Vector2 get rightUnit => Vector2(orientation.z, -orientation.x).normalized;

  /// 获取俯仰角正弦值
  double get pitchSin => -orientation.y;

  /// 更新玩家状态
  void update(double deltaTime, List<Block> blocks) {
    // 应用重力
    if (!isGrounded) {
      velocity = Vector3(
        velocity.x,
        velocity.y - Constants.gravity * deltaTime,
        velocity.z,
      );
    }

    // 限制下落速度
    if (velocity.y < -Constants.maxFallSpeed) {
      velocity = velocity.appointY(-Constants.maxFallSpeed);
    }

    // 保存当前位置用于碰撞检测
    final oldPosition = position;

    // 应用速度更新位置
    position += velocity * deltaTime;

    // 检测与方块的碰撞
    isGrounded = false;
    for (final block in blocks) {
      if (block.penetrable) continue;

      if (checkCollision(block.collider)) {
        _handleCollision(block.collider, oldPosition);
      }
    }
  }

  /// 处理碰撞
  void _handleCollision(BoxCollider block, Vector3 oldPosition) {
    final resolution = resolveCollision(block, oldPosition);

    position += resolution;

    // 根据碰撞方向更新状态
    if (resolution.y > 0) {
      isGrounded = true;
      velocity = velocity.appointY(0);
    } else if (resolution.y < 0) {
      velocity = velocity.appointY(0);
    }

    if (resolution.x != 0) velocity = velocity.appointX(0);
    if (resolution.z != 0) velocity = velocity.appointZ(0);
  }

  /// 跳跃
  void jump() {
    if (isGrounded) {
      isGrounded = false;
      velocity = velocity.appointY(Constants.jumpStrength);
    }
  }

  /// 移动
  void move(Vector2 input, double speed) {
    if (input.isZero) return;

    final moveDirection =
        (rightUnit * input.x + forwardUnit * input.y).normalized;
    velocity = Vector3(
      moveDirection.x * speed,
      velocity.y,
      moveDirection.y * speed,
    );
  }

  /// 旋转视角
  void rotateView(double deltaYaw, double deltaPitch) {
    final direction = orientation.normalized;

    final currentYaw = math.atan2(direction.x, direction.z);
    final currentPitch = -math.asin(direction.y.clamp(-1.0, 1.0));

    final newYaw = currentYaw + deltaYaw;
    final newPitch = (currentPitch - deltaPitch).clamp(
      -Constants.pitchLimit,
      Constants.pitchLimit,
    );

    orientation = Vector3(
      math.sin(newYaw) * math.cos(newPitch),
      -math.sin(newPitch),
      math.cos(newYaw) * math.cos(newPitch),
    ).normalized;
  }
}

/// 八叉树节点
class OctreeNode {
  final AABB bounds;
  final int depth;
  final int maxDepth;
  final int bucketSize;
  final List<Block> _blocks = [];
  final List<OctreeNode> _children = [];

  OctreeNode(
    this.bounds, {
    this.depth = 0,
    this.maxDepth = 6,
    this.bucketSize = 16,
  });

  bool get isLeaf => _children.isEmpty;

  /// 插入方块
  void insert(Block block) {
    if (!bounds.contains(block.position)) return;

    if (isLeaf && _blocks.length < bucketSize) {
      _blocks.add(block);
      return;
    }

    if (isLeaf && depth < maxDepth) {
      _subdivide();
    }

    if (isLeaf) {
      _blocks.add(block);
    } else {
      for (final child in _children) {
        child.insert(block);
      }
    }
  }

  /// 细分节点
  void _subdivide() {
    for (final childBox in bounds.split()) {
      _children.add(
        OctreeNode(
          childBox,
          depth: depth + 1,
          maxDepth: maxDepth,
          bucketSize: bucketSize,
        ),
      );
    }

    // 重新分发当前块
    for (final block in _blocks) {
      for (final child in _children) {
        child.insert(block);
      }
    }
    _blocks.clear();
  }

  /// 查询区域内的方块
  void query(AABB area, List<Block> results) {
    if (!bounds.intersects(area)) return;

    results.addAll(_blocks);

    for (final child in _children) {
      child.query(area, results);
    }
  }
}

/// 八叉树管理类
class Octree {
  final OctreeNode root;

  Octree(AABB worldBounds) : root = OctreeNode(worldBounds);

  /// 球体查询
  List<Block> querySphere(Vector3 center, double radius) {
    final queryBounds = AABB(
      Vector3(center.x - radius, center.y - radius, center.z - radius),
      Vector3(center.x + radius, center.y + radius, center.z + radius),
    );

    final results = <Block>[];
    root.query(queryBounds, results);
    return results;
  }

  /// 批量插入方块
  void insertAll(List<Block> blocks) {
    for (final block in blocks) {
      root.insert(block);
    }
  }
}

/// 裁剪平面
class ClipPlane {
  final Vector3 normal;
  final double distance;

  ClipPlane(this.normal, this.distance);

  /// 判断点是否在平面内
  bool isInside(Vector3 point) => point.dot(normal) >= distance;

  /// 计算线段与平面的交点
  Vector3? intersectLine(Vector3 start, Vector3 end) {
    final startDist = start.dot(normal) - distance;
    final endDist = end.dot(normal) - distance;

    if (startDist >= 0 && endDist >= 0) return null;
    if (startDist < 0 && endDist < 0) return null;

    final t = startDist / (startDist - endDist);
    return start + (end - start) * t;
  }
}

/// 视锥体
class Frustum {
  final List<ClipPlane> planes;

  Frustum()
    : planes = [
        ClipPlane(Vector3(0, 0, 1), Constants.nearClip), // 近平面
        ClipPlane(Vector3(0, 0, -1), -Constants.farClip), // 远平面
      ];

  /// 基于视角更新视锥体
  void updateWithView(Vector3 forward, Vector3 right, Vector3 up) {
    final fovRad = Constants.fieldOfView * 3.14159 / 180.0;
    final tanHalfFov = math.tan(fovRad * 0.5);

    planes.addAll([
      ClipPlane((forward - right * tanHalfFov).normalized, 0), // 右平面
      ClipPlane((forward + right * tanHalfFov).normalized, 0), // 左平面
      ClipPlane((forward - up * tanHalfFov).normalized, 0), // 上平面
      ClipPlane((forward + up * tanHalfFov).normalized, 0), // 下平面
    ]);
  }

  /// 判断点是否在视锥体内
  bool containsPoint(Vector3 point) {
    for (final plane in planes) {
      if (!plane.isInside(point)) return false;
    }
    return true;
  }
}
