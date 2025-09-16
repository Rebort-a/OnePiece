import 'dart:math';
import 'package:flutter/material.dart';

/// 游戏状态枚举
enum GameState { start, playing, paused, gameOver, levelUp }

/// 游戏对象基类
abstract class GameObject {
  Offset position;
  Size size;

  GameObject({required this.position, required this.size});

  Rect get rect => position & size;
}

/// 玩家类
class Player extends GameObject {
  Color color;
  bool invincible;
  int invincibleTimer;
  bool shield;
  bool tripleShot;
  int tripleShotTimer;
  bool flameBullet;
  int flameBulletTimer;
  bool bigBullet;
  int bigBulletTimer;

  Player({
    super.position = Offset.zero,
    super.size = const Size(40, 50),
    this.color = const Color(0xFF00F0FF),
    this.invincible = false,
    this.invincibleTimer = 0,
    this.shield = false,
    this.tripleShot = false,
    this.tripleShotTimer = 0,
    this.flameBullet = false,
    this.flameBulletTimer = 0,
    this.bigBullet = false,
    this.bigBulletTimer = 0,
  });
}

/// 敌人类型枚举
enum EnemyType { basic, fast, heavy, boss }

/// 敌人类
class Enemy extends GameObject {
  EnemyType type;
  double speed;
  double health;
  Color color;
  int points;
  double dx;
  bool isMovingDown;
  int minionSpawnTimer;

  Enemy({
    required this.type,
    required super.position,
    required super.size,
    required this.speed,
    required this.health,
    required this.color,
    required this.points,
    required this.dx,
    this.isMovingDown = true,
    this.minionSpawnTimer = 0,
  });
}

/// 子弹属性
class BulletConfig {
  final bool isBig;
  final bool isFlame;
  final double damage;
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
  BulletConfig config;
  Bullet({required super.position, required this.angle, required this.config})
    : super(size: config.size);
}

/// 道具类型枚举
enum PropType { tripleShot, shield, flame, bigBullet }

/// 道具类
class GameProp extends GameObject {
  PropType type;
  double speed;
  Color color;

  GameProp({
    required super.position,
    required super.size,
    required this.type,
    required this.speed,
    required this.color,
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
    bool active = false;
    for (var p in List.of(particles)) {
      p.position += p.velocity;
      p.life--;
      if (p.life <= 0) {
        particles.remove(p);
      } else {
        active = true;
      }
    }
    if (!active || alpha <= 0) finished = true;
  }
}

/// 星星背景类
class Star extends GameObject {
  double opacity;
  double speed;

  Star({
    required super.position,
    required super.size,
    required this.opacity,
    required this.speed,
  });
}

/// 警报类型枚举
enum AlertType { enemyEscaped, warning, info }

/// 游戏警报类
class GameAlert {
  String text;
  Color color;
  int duration;
  double opacity;
  int timer;
  AlertType type;

  GameAlert({
    required this.text,
    required this.color,
    this.duration = 60,
    this.opacity = 1.0,
    this.timer = 0,
    this.type = AlertType.info,
  });
}
