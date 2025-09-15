import 'package:flutter/material.dart';

import 'base.dart';
import 'manager.dart';

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
            builder: (_, __) {
              return Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: GamePainter(_manager),
                  ),
                  GestureDetector(
                    onPanUpdate: (details) =>
                        _manager.handleDrag(details.delta),
                    onTapDown: (_) => _manager.shoot(),
                  ),
                  KeyboardListener(
                    focusNode: _manager.focusNode,
                    onKeyEvent: _manager.handleKeyEvent,
                    child: const SizedBox.expand(),
                  ),

                  // 添加警报显示
                  ..._buildAlerts(),

                  if (_manager.gameState == GameState.start)
                    Center(
                      child: ElevatedButton(
                        onPressed: _manager.startGame,
                        child: const Text('开始游戏'),
                      ),
                    ),
                  if (_manager.gameState == GameState.levelUp)
                    Center(
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
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_manager.gameState == GameState.gameOver)
                    Center(
                      child: ElevatedButton(
                        onPressed: _manager.startGame,
                        child: const Text('再来一局'),
                      ),
                    ),

                  // 1. 返回按钮
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  // 2.生命 + 分数文本
                  Positioned(
                    top: 70,
                    right: 10,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // 文本左对齐，与返回键对齐
                      children: [
                        // 生命文本
                        Text(
                          '生命: ${_manager.lives}',
                          style: const TextStyle(
                            color: Colors.cyan,
                            fontSize: 18,
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
                        const SizedBox(height: 4), // 生命与分数间距
                        // 分数文本
                        Text(
                          '分数: ${_manager.score}',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 18,
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
                      ],
                    ),
                  ),

                  // 3. 暂停/继续按钮
                  Positioned(
                    top: 10,
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

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
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

  /// 生成屏幕顶部警报 Widget（最多同时一条）
  List<Widget> _buildAlerts() {
    final alert = _manager.alerts.isNotEmpty ? _manager.alerts.last : null;
    if (alert == null) return const [];

    return [
      Positioned(
        top: 10,
        left: 0,
        right: 0,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200), // 弹入速度
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -0.5), // 从上方滑入
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack, // 回弹效果
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(alert.hashCode), // 保证切换动画触发
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: alert.color.withValues(alpha: 0.9),
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

class GamePainter extends CustomPainter {
  final Manager manager;

  GamePainter(this.manager) : super(repaint: manager);

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景
    canvas.drawColor(const Color(0xFF0B1120), BlendMode.srcOver);

    // 绘制星星
    for (var star in manager.stars) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: star.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(star.position, star.size.width, paint);
    }

    // 绘制子弹
    for (var bullet in manager.bullets) {
      final paint = Paint()
        ..color = bullet.color
        ..style = PaintingStyle.fill;

      // 火焰子弹添加特殊效果
      if (bullet.type == BulletType.flame) {
        // 绘制主子弹
        canvas.drawRect(bullet.rect, paint);

        // 绘制火焰效果
        final glowPaint = Paint()
          ..color = bullet.color.withValues(alpha: 0.5)
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

    // 绘制敌人
    for (var enemy in manager.enemies) {
      final paint = Paint()
        ..color = enemy.color
        ..style = PaintingStyle.fill;

      switch (enemy.type) {
        case EnemyType.basic:
          // 绘制基础型敌人（三角形）
          final path = Path();
          path.moveTo(enemy.rect.center.dx, enemy.rect.top);
          path.lineTo(enemy.rect.left, enemy.rect.bottom);
          path.lineTo(enemy.rect.right, enemy.rect.bottom);
          path.close();
          canvas.drawPath(path, paint);

          // 绘制三角形发光效果
          final glowPaint = Paint()
            ..color = enemy.color.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;

          final glowPath = Path();
          glowPath.moveTo(enemy.rect.center.dx, enemy.rect.top - 5);
          glowPath.lineTo(enemy.rect.left - 5, enemy.rect.bottom);
          glowPath.lineTo(enemy.rect.right + 5, enemy.rect.bottom);
          glowPath.close();
          canvas.drawPath(glowPath, glowPaint);
          break;

        case EnemyType.fast:
          // 绘制快速型敌人（菱形）
          final path = Path();
          path.moveTo(enemy.rect.center.dx, enemy.rect.top);
          path.lineTo(enemy.rect.right, enemy.rect.center.dy);
          path.lineTo(enemy.rect.center.dx, enemy.rect.bottom);
          path.lineTo(enemy.rect.left, enemy.rect.center.dy);
          path.close();
          canvas.drawPath(path, paint);

          // 绘制菱形发光效果
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
          break;

        case EnemyType.heavy:
          // 绘制重型敌人（矩形+内部细节）
          canvas.drawRect(enemy.rect, paint);

          // 绘制内部细节
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

          // 绘制矩形发光效果
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
          break;
      }
    }

    // 绘制道具
    for (var gameProp in manager.gameProps) {
      // 计算中心位置（基于position和size属性）
      final center = Offset(
        gameProp.position.dx + gameProp.size.width / 2,
        gameProp.position.dy + gameProp.size.height / 2,
      );

      // 绘制能量道具主体（圆形）
      final paint = Paint()
        ..color = gameProp.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, gameProp.size.width / 2, paint);

      // 绘制发光效果（外圈半透明描边）
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

      // 更新道具文本标识
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

      // 将文本绘制在中心位置
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }

    // 绘制爆炸效果
    for (var explosion in manager.explosions) {
      for (var p in explosion.particles) {
        final paint = Paint()
          ..color = p.color.withValues(alpha: explosion.alpha * (p.life / 50))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p.position, p.radius, paint);
      }
    }

    if (manager.gameState != GameState.gameOver) {
      final player = manager.player;
      if (!player.invincible ||
          (player.invincible && (DateTime.now().millisecond % 200) < 100)) {
        // 绘制护盾
        if (player.shield) {
          // 内层护盾
          final shieldPaint = Paint()
            ..color = Colors.green.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;

          canvas.drawCircle(
            Offset(
              player.position.dx + player.size.width / 2,
              player.position.dy + player.size.height / 2,
            ),
            player.size.width * 0.7,
            shieldPaint,
          );

          // 外层护盾发光
          final shieldGlowPaint = Paint()
            ..color = Colors.green.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;

          canvas.drawCircle(
            Offset(
              player.position.dx + player.size.width / 2,
              player.position.dy + player.size.height / 2,
            ),
            player.size.width * 0.8,
            shieldGlowPaint,
          );
        }

        // 绘制玩家主体（三角形）
        final playerPaint = Paint()
          ..color = player.color
          ..style = PaintingStyle.fill;

        final path = Path()
          ..moveTo(
            player.position.dx + player.size.width / 2,
            player.position.dy,
          )
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
          ..moveTo(
            player.position.dx + player.size.width / 2,
            player.position.dy,
          )
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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
