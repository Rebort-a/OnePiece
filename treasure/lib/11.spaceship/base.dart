import 'dart:math';
import 'package:flutter/material.dart';

/// 游戏对象基类
abstract class GameObject {
  Offset position;
  final Size size;

  GameObject({required this.position, required this.size});

  Rect get rect => position & size;
}

/// 星星背景类
class Star extends GameObject {
  final double opacity;
  final double speed;

  Star({
    required super.position,
    required super.size,
    required this.opacity,
    required this.speed,
  });
}

/// 子弹属性配置
class BulletConfig {
  final bool isBig;
  final bool isFlame;
  final int damage;
  final Color color;
  final Size size;

  BulletConfig({
    required this.isBig,
    required this.isFlame,
    required this.damage,
    required this.color,
    required this.size,
  });
}

/// 子弹类
class Bullet extends GameObject {
  final double angle;
  final BulletConfig config;

  Bullet({required super.position, required this.angle, required this.config})
    : super(size: config.size);
}

/// 道具类型枚举
enum PropType { tripleShot, shield, flame, bigBullet }

/// 道具类型扩展方法
extension PropTypeExtension on PropType {
  static IconData getIcon(PropType type) {
    switch (type) {
      case PropType.tripleShot:
        return Icons.exposure_plus_2;
      case PropType.shield:
        return Icons.shield_outlined;
      case PropType.flame:
        return Icons.whatshot;
      case PropType.bigBullet:
        return Icons.zoom_in;
    }
  }

  static Color getColor(PropType type) {
    switch (type) {
      case PropType.tripleShot:
        return Colors.cyan;
      case PropType.shield:
        return Colors.green;
      case PropType.flame:
        return Colors.orange;
      case PropType.bigBullet:
        return Colors.amber;
    }
  }
}

/// 道具类
class GameProp extends GameObject {
  final PropType type;
  final double speed;

  GameProp({
    required super.position,
    required super.size,
    required this.type,
    required this.speed,
  });
}

/// 敌人类型枚举
enum EnemyType { basic, fast, heavy, boss }

/// 敌人类
class Enemy extends GameObject {
  final EnemyType type;
  final Color color;
  int health;
  final double speed;
  double dx;
  final int points;
  final double probability;

  Enemy({
    required super.position,
    required super.size,
    required this.type,
    required this.color,
    required this.health,
    required this.speed,
    required this.dx,
    required this.probability,
  }) : points = health;
}

/// 玩家类
class Player extends GameObject {
  Color color;
  int health;
  final double speed;
  bool shield;
  int invincibleTimer;
  int tripleShotTimer;
  int flameBulletTimer;
  int bigBulletTimer;
  bool flash;
  int flashTimer;

  bool get invincible => invincibleTimer > 0;
  bool get tripleShot => tripleShotTimer > 0;
  bool get flameBullet => flameBulletTimer > 0;
  bool get bigBullet => bigBulletTimer > 0;

  Player({
    super.position = Offset.zero,
    super.size = const Size(40, 50),
    required this.color,
    required this.health,
    required this.speed,
    this.shield = false,
    this.invincibleTimer = 0,
    this.tripleShotTimer = 0,
    this.flameBulletTimer = 0,
    this.bigBulletTimer = 0,
    this.flash = false,
    this.flashTimer = 0,
  });
}

/// 爆炸粒子类
class ExplosionParticle {
  Offset position;
  double radius;
  Color color;
  Offset velocity;
  int life;

  ExplosionParticle({
    required this.position,
    required this.radius,
    required this.color,
    required this.velocity,
    required this.life,
  });
}

/// 爆炸效果类
class Explosion {
  Offset position;
  double size;
  List<ExplosionParticle> particles;
  double alpha;
  bool finished;

  Explosion({required this.position, required this.size})
    : particles = [],
      alpha = 1.0,
      finished = false {
    _init();
  }

  /// 初始化爆炸粒子
  void _init() {
    final random = Random();
    for (int i = 0; i < size.toInt(); i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = random.nextDouble() * 3 + 1;
      particles.add(
        ExplosionParticle(
          position: position,
          radius: random.nextDouble() * 3 + 1,
          color: Color.fromRGBO(
            255,
            (random.nextDouble() * 100).toInt() + 100,
            0,
            1,
          ),
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          life: (random.nextDouble() * 30 + 20).toInt(),
        ),
      );
    }
  }

  /// 更新爆炸状态
  void update() {
    alpha -= 0.05;
    for (var p in particles) {
      p.position += p.velocity;
      p.life--;
    }
    particles.removeWhere((p) => p.life <= 0);
    finished = particles.isEmpty || alpha <= 0;
  }
}

/// 成就类型枚举
enum AchievementType {
  firstKill,
  score100,
  score500,
  score1000,
  level5,
  level10,
  bossKill,
  tripleKill,
}

/// 成就配置类
class Achievement {
  final AchievementType type;
  final String title;
  final String description;

  Achievement({
    required this.type,
    required this.title,
    required this.description,
  });
}

/// 所有成就列表
class Achievements {
  static List<Achievement> all = [
    Achievement(
      type: AchievementType.firstKill,
      title: "初露锋芒",
      description: "首次击败敌人",
    ),
    Achievement(
      type: AchievementType.score100,
      title: "百炼成钢",
      description: "得分达到100分",
    ),
    Achievement(
      type: AchievementType.score500,
      title: "半壁江山",
      description: "得分达到500分",
    ),
    Achievement(
      type: AchievementType.score1000,
      title: "千锤百炼",
      description: "得分达到1000分",
    ),
    Achievement(
      type: AchievementType.level5,
      title: "五级挑战",
      description: "达到5级",
    ),
    Achievement(
      type: AchievementType.level10,
      title: "十级大师",
      description: "达到10级",
    ),
    Achievement(
      type: AchievementType.bossKill,
      title: "Boss猎手",
      description: "首次击败BOSS",
    ),
    Achievement(
      type: AchievementType.tripleKill,
      title: "三连击",
      description: "一次击败3个敌人",
    ),
  ];
}
