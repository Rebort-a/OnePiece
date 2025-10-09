import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 三维向量类，用于表示3D空间中的位置、速度、力等
class Vector3 {
  final double x, y, z;
  const Vector3(this.x, this.y, this.z);

  /// 返回零向量
  factory Vector3.zero() => const Vector3(0, 0, 0);

  /// 向量加法
  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);

  /// 向量减法
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);

  /// 向量标量乘法
  Vector3 operator *(double scalar) =>
      Vector3(x * scalar, y * scalar, z * scalar);

  /// 向量标量除法
  Vector3 operator /(double scalar) =>
      Vector3(x / scalar, y / scalar, z / scalar);

  /// 向量的模（长度）
  double get magnitude => math.sqrt(x * x + y * y + z * z);

  /// 返回单位向量（归一化）
  Vector3 normalized() {
    final length = magnitude;
    // 避免除以零
    return length < 1e-6 ? Vector3.zero() : this / length;
  }

  /// 点积运算
  static double dot(Vector3 a, Vector3 b) => a.x * b.x + a.y * b.y + a.z * b.z;

  /// 叉积运算
  static Vector3 cross(Vector3 a, Vector3 b) => Vector3(
    a.y * b.z - a.z * b.y, // x分量
    a.z * b.x - a.x * b.z, // y分量
    a.x * b.y - a.y * b.x, // z分量
  );
}

/// 物理粒子类，表示模拟中的一个质点
class Particle {
  Vector3 position; // 位置
  Vector3 velocity; // 速度
  Vector3 _resultantForce = Vector3.zero(); // 合力
  double mass = 1.0; // 质量

  Particle({required this.position, Vector3? velocity, this.mass = 1.0})
    : velocity = velocity ?? Vector3.zero();

  /// 清除累积的力
  void clearForce() => _resultantForce = Vector3.zero();

  /// 添加力到粒子
  void addForce(Vector3 force) => _resultantForce = _resultantForce + force;

  /// 根据物理规则更新粒子的位置和速度
  void integrate(double deltaTime, double movementScale) {
    // F = ma => a = F/m
    final acceleration = _resultantForce / mass;

    // 更新速度：v = v + a * dt
    velocity = velocity + acceleration * deltaTime;

    // 更新位置：p = p + v * (dt * scale)
    position = position + velocity * (deltaTime * movementScale);
  }

  Vector3 get force => _resultantForce;
}

/// 弹簧类，连接两个粒子并模拟弹性力
class Spring {
  final Particle particleA, particleB; // 连接的两个粒子
  final double restLength; // 弹簧自然长度
  final double stiffness; // 刚度系数（胡克定律）
  final double damping; // 阻尼系数

  Spring(
    this.particleA,
    this.particleB,
    this.restLength, {
    this.stiffness = 25,
    this.damping = 0.4,
  });

  /// 应用弹簧力到连接的粒子
  void apply() {
    final displacement = particleB.position - particleA.position;
    final currentLength = displacement.magnitude;

    // 如果弹簧长度接近零，避免数值不稳定
    if (currentLength < 1e-6) return;

    final direction = displacement.normalized(); // 弹簧方向单位向量
    final relativeVelocity = particleB.velocity - particleA.velocity; // 相对速度

    // 计算阻尼力（与相对速度在弹簧方向上的分量成正比）
    final dampingForce = Vector3.dot(relativeVelocity, direction) * damping;

    // 计算拉伸量
    final stretch = currentLength - restLength;

    // 胡克定律 + 阻尼：F = -k * Δx - c * v
    final forceMagnitude = -stiffness * stretch - dampingForce;
    final force = direction * forceMagnitude;

    // 作用力与反作用力：A受到反向力，B受到正向力
    particleA.addForce(force * -1);
    particleB.addForce(force);
  }

  /// 当前弹簧长度
  double get currentLength =>
      (particleB.position - particleA.position).magnitude;
}

/// 软体圆柱模拟类
class SoftCylinder {
  final List<Particle> particles = []; // 所有粒子
  final List<Spring> springs = []; // 所有弹簧

  final Vector3 center; // 圆柱中心位置
  final int faceCount; // 圆柱面数（粒子数量）
  final double radius; // 圆柱半径
  final double width; // 圆柱宽度（x轴方向）
  final double movementScale; // 运动缩放因子
  final double elasticity; // 弹性系数
  final double damping; // 阻尼系数

  // 边界框约束
  final double minX = -400;
  final double maxX = 400;
  final double minY = -400;
  final double maxY = 400;
  final double minZ = 400;
  final double maxZ = 1200;
  final double restitution = 0.8; // 碰撞恢复系数

  SoftCylinder({
    required this.center,
    this.faceCount = 160,
    this.radius = 32,
    this.width = 16,
    this.movementScale = 16,
    this.elasticity = 25,
    this.damping = 0.4,
  }) {
    _buildCylinderStructure();
  }

  /// 计算系统的总动能
  double get kineticEnergy => particles
      .map(
        (particle) =>
            0.5 *
            particle.mass *
            particle.velocity.magnitude *
            particle.velocity.magnitude,
      )
      .reduce((a, b) => a + b);

  /// 构建圆柱的物理结构（粒子和弹簧网络）
  void _buildCylinderStructure() {
    // 创建粒子：在圆周上均匀分布
    for (int i = 0; i < faceCount; i++) {
      final angle = 2 * math.pi / faceCount * i; // 角度
      final offset = Vector3(
        (i % 2 == 0 ? width : -width), // x方向：交替正负创建厚度
        radius * math.sin(angle), // y坐标
        radius * math.cos(angle), // z坐标
      );
      final position = center + offset;

      particles.add(Particle(position: position));
    }

    // 创建弹簧连接：构建三角形网格以增加稳定性
    for (int i = 0; i < faceCount; i++) {
      final neighbor1 = (i + 1) % faceCount; // 相邻粒子
      final neighbor2 = (i + 2) % faceCount; // 隔一个粒子
      final opposite = (i + faceCount ~/ 2) % faceCount; // 对面粒子

      springs.add(_createSpring(i, neighbor1));
      springs.add(_createSpring(i, neighbor2));
      springs.add(_createSpring(i, opposite));
    }
  }

  /// 在两个粒子间创建弹簧
  Spring _createSpring(int particleIndexA, int particleIndexB) {
    final particleA = particles[particleIndexA];
    final particleB = particles[particleIndexB];
    final restLength = (particleB.position - particleA.position).magnitude;
    return Spring(
      particleA,
      particleB,
      restLength,
      stiffness: elasticity,
      damping: damping,
    );
  }

  /// 对所有粒子施加力
  void applyForce(Vector3 force) {
    for (final particle in particles) {
      particle.addForce(force);
    }
  }

  /// 执行物理模拟的一步
  void simulateStep(double deltaTime, Vector3 externalForce) {
    // 1. 清除所有粒子的累积力
    for (final particle in particles) {
      particle.clearForce();
    }

    // 2. 应用内力
    for (final spring in springs) {
      spring.apply();
    }

    // 3. 应用外力
    for (final particle in particles) {
      particle.addForce(externalForce);
    }

    // 4. 积分更新所有粒子状态并处理边界碰撞
    for (final particle in particles) {
      particle.integrate(deltaTime, movementScale);
      _handleBoundaryCollision(particle);
    }
  }

  /// 处理粒子与边界的碰撞
  void _handleBoundaryCollision(Particle p) {
    // X轴碰撞
    if (p.position.x < minX) {
      p.position = Vector3(
        minX - (p.position.x - minX),
        p.position.y,
        p.position.z,
      );
      p.velocity = Vector3(
        -p.velocity.x * restitution,
        p.velocity.y,
        p.velocity.z,
      );
    } else if (p.position.x > maxX) {
      p.position = Vector3(
        maxX - (p.position.x - maxX),
        p.position.y,
        p.position.z,
      );
      p.velocity = Vector3(
        -p.velocity.x * restitution,
        p.velocity.y,
        p.velocity.z,
      );
    }

    // Y轴碰撞
    if (p.position.y < minY) {
      p.position = Vector3(
        p.position.x,
        minY - (p.position.y - minY),
        p.position.z,
      );
      p.velocity = Vector3(
        p.velocity.x,
        -p.velocity.y * restitution,
        p.velocity.z,
      );
    } else if (p.position.y > maxY) {
      p.position = Vector3(
        p.position.x,
        maxY - (p.position.y - maxY),
        p.position.z,
      );
      p.velocity = Vector3(
        p.velocity.x,
        -p.velocity.y * restitution,
        p.velocity.z,
      );
    }

    if (p.position.z < minZ) {
      p.position = Vector3(
        p.position.x,
        p.position.y,
        1.0 - (p.position.z - 1.0),
      );
      p.velocity = Vector3(
        p.velocity.x,
        p.velocity.y,
        -p.velocity.z * restitution,
      );
    } else if (p.position.z > maxZ) {
      p.position = Vector3(
        p.position.x,
        p.position.y,
        maxZ - (p.position.z - maxZ),
      );
      p.velocity = Vector3(
        p.velocity.x,
        p.velocity.y,
        -p.velocity.z * restitution,
      );
    }
  }
}

/// 软体圆柱的自定义绘制器
class SoftCylinderPainter extends CustomPainter {
  final SoftCylinder cylinder; // 要绘制的圆柱
  final double flashAlpha; // 闪光效果透明度

  static const double _focalLength = 400; // 透视投影的焦距

  SoftCylinderPainter({required this.cylinder, this.flashAlpha = 1.0});

  /// 将3D x坐标投影到2D屏幕坐标
  double _projectX(Vector3 point, Size screenSize) {
    final scale = _focalLength / point.z;
    return point.x * scale + screenSize.width / 2;
  }

  /// 将3D y坐标投影到2D屏幕坐标
  double _projectY(Vector3 point, Size screenSize) {
    final scale = _focalLength / point.z;
    return -point.y * scale + screenSize.height / 2; // 注意y轴翻转
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景（带闪光效果）
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = HSLColor.fromAHSL(flashAlpha, 200, 0.99, 0.10).toColor(),
    );

    // 按z坐标排序粒子（从远到近绘制，实现正确的深度顺序）
    final sortedIndices =
        List<int>.generate(cylinder.particles.length, (index) => index)..sort(
          (indexA, indexB) => cylinder.particles[indexB].position.z.compareTo(
            cylinder.particles[indexA].position.z,
          ),
        );

    const double primaryHue = 180; // 主色调（青色）
    const double secondaryHue = 220; // 辅色调（蓝色）
    final int particleCount = cylinder.particles.length;

    // 绘制每个四边形面
    for (final index in sortedIndices) {
      // 获取构成四边形的四个粒子索引
      final currentIndex = index;
      final nextIndex = (index + 1) % particleCount;
      final oppositeIndex1 = (index + 3) % particleCount;
      final oppositeIndex2 = (index + 2) % particleCount;

      final point0 = cylinder.particles[currentIndex].position;
      final point1 = cylinder.particles[nextIndex].position;
      final point2 = cylinder.particles[oppositeIndex1].position;
      final point3 = cylinder.particles[oppositeIndex2].position;

      // 计算法向量用于光照
      final edge1 = point1 - point0;
      final edge2 = point3 - point0;
      final normal = Vector3.cross(edge1, edge2).normalized();
      final viewDirection = Vector3(0, 0, -1).normalized(); // 视线方向

      // 计算光照强度（基于法向量与视线方向的夹角）
      double lightIntensity = Vector3.dot(normal, viewDirection);
      if (lightIntensity.isNaN) lightIntensity = 0; // 处理无效值

      // 将光照强度转换为亮度
      final brightness = (-lightIntensity * 70).clamp(10.0, 70.0);
      final lightness = brightness / 100.0;

      // 创建四边形路径
      final quadPath = Path()
        ..moveTo(_projectX(point0, size), _projectY(point0, size))
        ..lineTo(_projectX(point1, size), _projectY(point1, size))
        ..lineTo(_projectX(point2, size), _projectY(point2, size))
        ..lineTo(_projectX(point3, size), _projectY(point3, size))
        ..close();

      // 只绘制背向观察者的面（背面剔除）
      if (lightIntensity <= 0) {
        // 交替使用两种色调
        final hue = index % 2 == 0 ? primaryHue : secondaryHue;
        canvas.drawPath(
          quadPath,
          Paint()
            ..style = PaintingStyle.fill
            ..color = HSLColor.fromAHSL(1, hue, 0.99, lightness).toColor(),
        );
      }

      // 绘制边框
      canvas.drawPath(
        quadPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withAlpha((0.3 * flashAlpha * 255).toInt()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant SoftCylinderPainter oldDelegate) => true;
}
