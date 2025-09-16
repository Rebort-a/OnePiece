import 'dart:math';

import 'package:flutter/material.dart';

enum GameState { start, playing, paused, gameOver, levelUp }

abstract class GameObject {
  Offset position;
  Size size;

  GameObject({required this.position, required this.size});

  Rect get rect => position & size;
}

class Player extends GameObject {
  Color color;
  bool invincible;
  int invincibleTimer;
  bool shield; // 护盾
  bool tripleShot; // 三向子弹
  int tripleShotTimer;
  bool flameBullet; // 火焰子弹
  int flameBulletTimer;
  bool bigBullet; // 大子弹
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

enum EnemyType { basic, fast, heavy, boss }

class Enemy extends GameObject {
  EnemyType type;
  double speed;
  double health;
  Color color;
  int points;
  double? dx;
  bool isMovingDown; // 是否正在向下移动（仅BOSS使用）
  int minionSpawnTimer; // 生成小敌人的计时器（仅BOSS使用）

  Enemy({
    required this.type,
    required super.position,
    required super.size,
    required this.speed,
    required this.health,
    required this.color,
    required this.points,
    this.dx,
    // BOSS默认属性
    this.isMovingDown = true,
    this.minionSpawnTimer = 0,
  });
}

class Bullet extends GameObject {
  final bool isBig;
  final bool isFlame;
  final double damage;
  final Color color;
  final double angle;

  Bullet({
    required this.isBig,
    required this.isFlame,
    required this.damage,
    required super.position,
    required super.size,
    required this.color,
    required this.angle,
  });
}

enum PropType { tripleShot, shield, flame, bigBullet }

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

  void _init() {
    for (int i = 0; i < size.toInt(); i++) {
      final angle = Random().nextDouble() * 2 * 3.1415;
      final speed = Random().nextDouble() * 3 + 1;
      particles.add(
        ExplosionParticle(
          position: position,
          radius: Random().nextDouble() * 3 + 1,
          color: Color.fromRGBO(
            255,
            (Random().nextDouble() * 100).toInt() + 100,
            0,
            1,
          ),
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          life: (Random().nextDouble() * 30 + 20).toInt(),
        ),
      );
    }
  }

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

// 添加警报类型枚举
enum AlertType { enemyEscaped, warning, info }

// 警报类
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
