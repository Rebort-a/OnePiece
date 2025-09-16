import 'dart:math';
import 'package:flutter/material.dart';
import 'base.dart';
import 'manager.dart';

/// 太空飞船游戏页面
class SpaceShipPage extends StatelessWidget {
  final _manager = Manager();

  SpaceShipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_manager.screenSize == Size.zero) {
            _manager.initGame(constraints.biggest);
          } else {
            _manager.changeSize(constraints.biggest);
          }

          return AnimatedBuilder(
            animation: _manager,
            builder: (_, _) {
              return Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: GamePainter(_manager),
                  ),

                  ..._buildAlerts(),

                  // 手势控制
                  GestureDetector(
                    onPanUpdate: (details) =>
                        _manager.handleDrag(details.delta),
                    onTapDown: (_) => _manager.shoot(),
                  ),

                  // 键盘监听
                  KeyboardListener(
                    focusNode: _manager.focusNode,
                    onKeyEvent: _manager.handleKeyEvent,
                    child: const SizedBox.expand(),
                  ),

                  // 游戏状态UI
                  if (_manager.gameState == GameState.start)
                    _buildStartScreen(),

                  if (_manager.gameState == GameState.paused)
                    _buildPauseScreen(),

                  if (_manager.gameState == GameState.levelUp)
                    _buildLevelUpScreen(),

                  if (_manager.gameState == GameState.gameOver)
                    _buildGameOverScreen(),

                  // 顶部控制按钮
                  Positioned(
                    top: 20,
                    left: 10,
                    child: _buildIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // 游戏信息
                  Positioned(
                    top: 80,
                    right: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '生命: ${_manager.lives}',
                          style: _infoTextStyle(Colors.cyan),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '分数: ${_manager.score}',
                          style: _infoTextStyle(Colors.yellow),
                        ),
                      ],
                    ),
                  ),

                  // 暂停/继续按钮
                  Positioned(
                    top: 20,
                    right: 10,
                    child: _buildIconButton(
                      icon: _manager.gameState == GameState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                      onPressed: () => _manager.gameState == GameState.paused
                          ? _manager.resumeGame()
                          : _manager.pauseGame(),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 构建开始屏幕
  Widget _buildStartScreen() {
    return Center(
      child: ElevatedButton(
        onPressed: _manager.startGame,
        child: const Text('开始游戏'),
      ),
    );
  }

  /// 构建暂停屏幕
  Widget _buildPauseScreen() {
    return Center(
      child: ElevatedButton(
        onPressed: _manager.resumeGame,
        child: const Text('继续游戏'),
      ),
    );
  }

  /// 构建升级屏幕
  Widget _buildLevelUpScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '等级提升',
            style: TextStyle(
              color: Colors.green,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '当前等级: ${_manager.level}',
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            '准备迎接更难的挑战!',
            style: TextStyle(color: Colors.yellow, fontSize: 18),
          ),
        ],
      ),
    );
  }

  /// 构建游戏结束屏幕
  Widget _buildGameOverScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '游戏结束',
            style: TextStyle(
              color: Colors.green,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '当前等级: ${_manager.level}',
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _manager.startGame,
            child: const Text('再来一局'),
          ),
        ],
      ),
    );
  }

  /// 构建图标按钮
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(25),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: 25,
      ),
    );
  }

  /// 信息文本样式
  TextStyle _infoTextStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
      ],
    );
  }

  /// 生成屏幕警报
  List<Widget> _buildAlerts() {
    if (_manager.alerts.isEmpty) return const [];
    final alert = _manager.alerts.last;

    return [
      Positioned(
        top: 20,
        left: 0,
        right: 0,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(alert.hashCode),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(191), // 0.75透明度
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: alert.color.withAlpha(229), // 0.9透明度
                  width: 2,
                ),
              ),
              child: Text(
                alert.text,
                style: TextStyle(
                  color: alert.color,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// 游戏绘制器
class GamePainter extends CustomPainter {
  final Manager manager;

  GamePainter(this.manager) : super(repaint: manager);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas);
    _drawStars(canvas);
    _drawBullets(canvas);
    _drawEnemies(canvas);
    _drawProps(canvas);
    _drawExplosions(canvas);

    if (manager.gameState != GameState.gameOver) {
      _drawPlayer(canvas);
    }
  }

  /// 绘制背景
  void _drawBackground(Canvas canvas) {
    canvas.drawColor(const Color(0xFF0B1120), BlendMode.srcOver);
  }

  /// 绘制星星
  void _drawStars(Canvas canvas) {
    for (var star in manager.stars) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: star.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(star.position, star.size.width, paint);
    }
  }

  /// 绘制子弹
  void _drawBullets(Canvas canvas) {
    for (var bullet in manager.bullets) {
      final paint = Paint()
        ..color = bullet.config.color
        ..style = PaintingStyle.fill;

      // 火焰子弹添加特殊效果
      if (bullet.config.isFlame) {
        canvas.drawRect(bullet.rect, paint);

        final glowPaint = Paint()
          ..color = bullet.config.color.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(
            bullet.rect.left - 2,
            bullet.rect.top,
            bullet.rect.width + 4,
            bullet.rect.height * 1.5,
          ),
          glowPaint,
        );
      } else {
        canvas.drawRect(bullet.rect, paint);
      }
    }
  }

  /// 绘制敌人
  void _drawEnemies(Canvas canvas) {
    for (var enemy in manager.enemies) {
      final paint = Paint()
        ..color = enemy.color
        ..style = PaintingStyle.fill;

      switch (enemy.type) {
        case EnemyType.basic:
          _drawBasicEnemy(canvas, enemy, paint);
          break;
        case EnemyType.fast:
          _drawFastEnemy(canvas, enemy, paint);
          break;
        case EnemyType.heavy:
          _drawHeavyEnemy(canvas, enemy, paint);
          break;
        case EnemyType.boss:
          _drawBossEnemy(canvas, enemy, paint);
          break;
      }
    }
  }

  /// 绘制基础敌人
  void _drawBasicEnemy(Canvas canvas, Enemy enemy, Paint paint) {
    final path = Path();
    path.moveTo(enemy.rect.center.dx, enemy.rect.top);
    path.lineTo(enemy.rect.left, enemy.rect.bottom);
    path.lineTo(enemy.rect.right, enemy.rect.bottom);
    path.close();
    canvas.drawPath(path, paint);

    // 血量为满时显示发光效果
    if (enemy.health > 1.0) {
      final glowPaint = Paint()
        ..color = enemy.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final glowPath = Path();
      glowPath.moveTo(enemy.rect.center.dx, enemy.rect.top - 5);
      glowPath.lineTo(enemy.rect.left - 5, enemy.rect.bottom);
      glowPath.lineTo(enemy.rect.right + 5, enemy.rect.bottom);
      glowPath.close();
      canvas.drawPath(glowPath, glowPaint);
    }
  }

  /// 绘制快速敌人
  void _drawFastEnemy(Canvas canvas, Enemy enemy, Paint paint) {
    final path = Path();
    path.moveTo(enemy.rect.center.dx, enemy.rect.top);
    path.lineTo(enemy.rect.right, enemy.rect.center.dy);
    path.lineTo(enemy.rect.center.dx, enemy.rect.bottom);
    path.lineTo(enemy.rect.left, enemy.rect.center.dy);
    path.close();
    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = enemy.color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final glowPath = Path();
    glowPath.moveTo(enemy.rect.center.dx, enemy.rect.top - 3);
    glowPath.lineTo(enemy.rect.right + 3, enemy.rect.center.dy);
    glowPath.lineTo(enemy.rect.center.dx, enemy.rect.bottom + 3);
    glowPath.lineTo(enemy.rect.left - 3, enemy.rect.center.dy);
    glowPath.close();
    canvas.drawPath(glowPath, glowPaint);
  }

  /// 绘制重型敌人
  void _drawHeavyEnemy(Canvas canvas, Enemy enemy, Paint paint) {
    canvas.drawRect(enemy.rect, paint);

    final detailPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        enemy.rect.left + 5,
        enemy.rect.top + 5,
        enemy.rect.width - 10,
        enemy.rect.height - 10,
      ),
      detailPaint,
    );

    final glowPaint = Paint()
      ..color = enemy.color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        enemy.rect.left - 3,
        enemy.rect.top - 3,
        enemy.rect.width + 6,
        enemy.rect.height + 6,
      ),
      glowPaint,
    );
  }

  /// 绘制BOSS敌人
  void _drawBossEnemy(Canvas canvas, Enemy enemy, Paint paint) {
    final centerX = enemy.rect.center.dx;
    final centerY = enemy.rect.center.dy;
    final radius = enemy.size.width / 2;

    // 绘制六边形
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = 2 * pi * i / 6;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // 绘制BOSS中心核心
    final corePaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius / 3, corePaint);

    // 绘制BOSS护盾效果
    final shieldPaint = Paint()
      ..color = enemy.color.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(centerX, centerY), radius + 10, shieldPaint);

    // 绘制BOSS生命值条
    final healthBarWidth = enemy.size.width * 0.8;
    final maxHealth = 9 + (manager.level - 1) * 3;
    final healthPercent = enemy.health / maxHealth;
    final healthBarPaint = Paint()
      ..color = Color.lerp(Colors.red, Colors.green, healthPercent)!
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - healthBarWidth / 2,
        enemy.rect.top - 15,
        healthBarWidth * healthPercent,
        8,
      ),
      healthBarPaint,
    );

    // 生命值条边框
    final borderPaint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(
      Rect.fromLTWH(
        centerX - healthBarWidth / 2,
        enemy.rect.top - 15,
        healthBarWidth,
        8,
      ),
      borderPaint,
    );
  }

  /// 绘制道具
  void _drawProps(Canvas canvas) {
    for (var gameProp in manager.gameProps) {
      final center = Offset(
        gameProp.position.dx + gameProp.size.width / 2,
        gameProp.position.dy + gameProp.size.height / 2,
      );

      // 绘制道具主体
      final paint = Paint()
        ..color = gameProp.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, gameProp.size.width / 2, paint);

      // 绘制发光效果
      final glowPaint = Paint()
        ..color = gameProp.color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, gameProp.size.width / 2 + 3, glowPaint);

      // 绘制文本标识
      final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      String propText;
      switch (gameProp.type) {
        case PropType.tripleShot:
          propText = 'T';
          break;
        case PropType.shield:
          propText = 'S';
          break;
        case PropType.flame:
          propText = 'F';
          break;
        case PropType.bigBullet:
          propText = 'B';
          break;
      }

      textPainter.text = TextSpan(
        text: propText,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  /// 绘制爆炸效果
  void _drawExplosions(Canvas canvas) {
    for (var explosion in manager.explosions) {
      for (var p in explosion.particles) {
        final paint = Paint()
          ..color = p.color.withValues(alpha: explosion.alpha * (p.life / 50))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p.position, p.radius, paint);
      }
    }
  }

  /// 绘制玩家
  void _drawPlayer(Canvas canvas) {
    final player = manager.player;
    if (player.invincible && (DateTime.now().millisecond % 200) >= 100) {
      return; // 无敌状态闪烁效果
    }

    // 绘制护盾
    if (player.shield) {
      _drawPlayerShield(canvas, player);
    }

    // 绘制玩家主体
    _drawPlayerShip(canvas, player);
  }

  /// 绘制玩家护盾
  void _drawPlayerShield(Canvas canvas, Player player) {
    final center = Offset(
      player.position.dx + player.size.width / 2,
      player.position.dy + player.size.height / 2,
    );

    // 内层护盾
    final shieldPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, player.size.width * 0.7, shieldPaint);

    // 外层护盾发光
    final shieldGlowPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, player.size.width * 0.8, shieldGlowPaint);
  }

  /// 绘制玩家飞船
  void _drawPlayerShip(Canvas canvas, Player player) {
    final playerPaint = Paint()
      ..color = player.color
      ..style = PaintingStyle.fill;

    // 绘制主体
    final path = Path()
      ..moveTo(player.position.dx + player.size.width / 2, player.position.dy)
      ..lineTo(player.position.dx, player.position.dy + player.size.height)
      ..lineTo(
        player.position.dx + player.size.width,
        player.position.dy + player.size.height,
      )
      ..close();
    canvas.drawPath(path, playerPaint);

    // 绘制主体发光效果
    final glowPaint = Paint()
      ..color = player.color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final glowPath = Path()
      ..moveTo(player.position.dx + player.size.width / 2, player.position.dy)
      ..lineTo(
        player.position.dx + 5,
        player.position.dy + player.size.height - 10,
      )
      ..lineTo(
        player.position.dx + player.size.width - 5,
        player.position.dy + player.size.height - 10,
      )
      ..close();
    canvas.drawPath(glowPath, glowPaint);

    // 绘制细节装饰
    final detailPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        player.position.dx + player.size.width / 2 - 5,
        player.position.dy + player.size.height / 2,
        10,
        15,
      ),
      detailPaint,
    );

    // 绘制引擎效果
    final enginePaint = Paint()
      ..color = Colors.pink.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final enginePath = Path()
      ..moveTo(
        player.position.dx + player.size.width / 2 - 8,
        player.position.dy + player.size.height,
      )
      ..lineTo(
        player.position.dx + player.size.width / 2,
        player.position.dy + player.size.height + 10,
      )
      ..lineTo(
        player.position.dx + player.size.width / 2 + 8,
        player.position.dy + player.size.height,
      )
      ..close();
    canvas.drawPath(enginePath, enginePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
