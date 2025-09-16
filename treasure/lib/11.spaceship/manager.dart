import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'base.dart';

/// 游戏管理器
class Manager with ChangeNotifier implements TickerProvider {
  final Random _random = Random();
  late Ticker _ticker;
  Size _screenSize = Size.zero;
  GameState _gameState = GameState.start;

  Player _player = Player();
  final List<Bullet> _bullets = [];
  final List<Enemy> _enemies = [];
  final List<GameProp> _gameProps = [];
  final List<Explosion> _explosions = [];
  final List<Star> _stars = [];

  int _score = 0;
  int _lives = 3;
  int _level = 1;
  int _enemiesDestroyed = 0;
  int _spawnTimer = 0;
  int _cooldown = 0;

  Enemy? _boss;
  final List<GameAlert> _alerts = [];
  final FocusNode focusNode = FocusNode();

  // 按键状态
  bool _isUpPressed = false;
  bool _isDownPressed = false;
  bool _isLeftPressed = false;
  bool _isRightPressed = false;
  bool _isSpacePressed = false;

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  /// 初始化游戏
  void initGame(Size size) {
    changeSize(size);
    _resetPlayer();
    _ticker = createTicker((_) => _update());
    _ticker.start();
  }

  /// 更新屏幕尺寸
  void changeSize(Size size) {
    _screenSize = size;
    _createStars();
  }

  /// 创建背景星星
  void _createStars() {
    _stars.clear();
    final count = (_screenSize.width * _screenSize.height / 1000).toInt();
    for (int i = 0; i < count; i++) {
      _stars.add(
        Star(
          position: Offset(
            _random.nextDouble() * _screenSize.width,
            _random.nextDouble() * _screenSize.height,
          ),
          size: Size.square(_random.nextDouble() * 1.5),
          opacity: _random.nextDouble(),
          speed: _random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
  }

  /// 重置玩家状态
  void _resetPlayer() {
    _player = Player(
      position: Offset(_screenSize.width / 2 - 20, _screenSize.height - 70),
    );
  }

  /// 主更新循环
  void _update() {
    if (_gameState == GameState.playing) {
      _updateStars();
      _handleLongPressActions();
      _updatePlayer();
      _updateBullets();

      if (hasBoss) {
        _updateBoss();
      } else {
        _spawnEnemies();
      }

      _updateEnemies();
      _updateGameProps();
      _updateExplosions();
      _updateAlerts();
      _checkCollisions();
      notifyListeners();
    }
  }

  /// 更新星星位置
  void _updateStars() {
    for (var star in _stars) {
      star.position += Offset(0, star.speed);
      if (star.position.dy > _screenSize.height) {
        star.position = Offset(_random.nextDouble() * _screenSize.width, 0);
      }
    }
  }

  /// 处理长按操作
  void _handleLongPressActions() {
    const double moveSpeed = 5.0;

    // 方向键移动
    if (_isUpPressed) _player.position += Offset(0, -moveSpeed);
    if (_isDownPressed) _player.position += Offset(0, moveSpeed);
    if (_isLeftPressed) _player.position += Offset(-moveSpeed, 0);
    if (_isRightPressed) _player.position += Offset(moveSpeed, 0);

    // 空格键射击
    if (_isSpacePressed && _cooldown <= 0) shoot();
  }

  /// 更新玩家状态
  void _updatePlayer() {
    // 限制玩家在屏幕内
    _player.position = Offset(
      _player.position.dx.clamp(0, _screenSize.width - _player.size.width),
      _player.position.dy.clamp(0, _screenSize.height - _player.size.height),
    );

    // 更新冷却和状态计时器
    if (_cooldown > 0) _cooldown--;

    if (_player.invincible) {
      _player.invincibleTimer--;
      if (_player.invincibleTimer <= 0) _player.invincible = false;
    }

    if (_player.tripleShot) {
      _player.tripleShotTimer--;
      if (_player.tripleShotTimer <= 0) _player.tripleShot = false;
    }

    if (_player.flameBullet) {
      _player.flameBulletTimer--;
      if (_player.flameBulletTimer <= 0) _player.flameBullet = false;
    }

    if (_player.bigBullet) {
      _player.bigBulletTimer--;
      if (_player.bigBulletTimer <= 0) _player.bigBullet = false;
    }
  }

  /// 更新子弹位置
  void _updateBullets() {
    for (var b in List.of(_bullets)) {
      final rad = b.angle * pi / 180;
      b.position += Offset(sin(rad) * 7, -cos(rad) * 7);
      if (b.position.dy < -b.size.height) _bullets.remove(b);
    }
  }

  /// 生成敌人
  void _spawnEnemies() {
    if (hasBoss) return;

    _spawnTimer++;
    final rate = 100 - (_level - 1) * 5;

    if (_spawnTimer >= rate) {
      _spawnTimer = 0;
      final type = _random.nextDouble();
      late Enemy enemy;

      if (type < 0.6) {
        // 基础敌人
        enemy = Enemy(
          type: EnemyType.basic,
          position: Offset(
            _random.nextDouble() * (_screenSize.width - 30),
            -30,
          ),
          size: const Size(30, 30),
          speed: 2 + (_level - 1) * 0.3,
          health: 1.5,
          color: Colors.red,
          points: 10,
          dx: 0,
        );
      } else if (type < 0.9) {
        // 快速敌人
        enemy = Enemy(
          type: EnemyType.fast,
          position: Offset(
            _random.nextDouble() * (_screenSize.width - 20),
            -20,
          ),
          size: const Size(20, 20),
          speed: 4 + (_level - 1) * 0.5,
          health: 1,
          color: Colors.yellow,
          points: 5,
          dx: (_random.nextDouble() - 0.5) * 2,
        );
      } else {
        // 重型敌人
        enemy = Enemy(
          type: EnemyType.heavy,
          position: Offset(
            _random.nextDouble() * (_screenSize.width - 40),
            -40,
          ),
          size: const Size(40, 40),
          speed: 1 + (_level - 1) * 0.2,
          health: 4,
          color: Colors.purple,
          points: 15,
          dx: 0,
        );
      }

      _enemies.add(enemy);
    }
  }

  /// 更新敌人位置
  void _updateEnemies() {
    for (var e in List.of(_enemies)) {
      if (e.type == EnemyType.boss) continue;

      e.position += Offset(e.dx, e.speed);

      if (e.position.dx < 0 ||
          e.position.dx > _screenSize.width - e.size.width) {
        e.dx = -e.dx;
      }

      // 敌人逃出屏幕
      if (e.position.dy > _screenSize.height) {
        _enemies.remove(e);
        if (e.type != EnemyType.fast) {
          _score = (_score - 5).clamp(0, double.infinity).toInt();
          showAlert("敌人逃脱!", Colors.red, AlertType.enemyEscaped);
        }
      }
    }
  }

  /// 生成BOSS
  void _spawnBoss() {
    if (hasBoss) return;

    _boss = Enemy(
      type: EnemyType.boss,
      position: Offset(_screenSize.width / 2 - 60, -60),
      size: const Size(60, 60),
      speed: 1.5,
      health: 9 + (_level - 1) * 3,
      color: Colors.redAccent,
      points: 20,
      dx: 2.0,
      isMovingDown: true,
    );

    _enemies.add(_boss!);
    showAlert("BOSS出现!", Colors.redAccent, AlertType.warning);
  }

  /// 更新BOSS状态
  void _updateBoss() {
    if (_boss == null) return;

    // BOSS移动逻辑
    if (_boss!.isMovingDown) {
      _boss!.position += Offset(0, _boss!.speed);
      if (_boss!.position.dy >= _screenSize.height / 3) {
        _boss!.isMovingDown = false;
      }
    } else {
      // 左右移动，碰到边界反弹
      _boss!.position += Offset(_boss!.dx, 0);
      if (_boss!.position.dx < 0 ||
          _boss!.position.dx > _screenSize.width - _boss!.size.width) {
        _boss!.dx = -_boss!.dx;
      }
    }

    // BOSS生成小敌人
    _boss!.minionSpawnTimer++;
    if (_boss!.minionSpawnTimer >= 120) {
      _boss!.minionSpawnTimer = 0;
      _enemies.add(
        Enemy(
          type: EnemyType.fast,
          position: Offset(
            _boss!.position.dx + _boss!.size.width / 2 - 10,
            _boss!.position.dy + _boss!.size.height / 2,
          ),
          size: const Size(20, 20),
          speed: 4 + (_level - 1) * 0.5,
          health: 1,
          color: Colors.yellow,
          points: 5,
          dx: (_random.nextDouble() - 0.5) * 2,
        ),
      );
    }
  }

  /// 更新道具位置
  void _updateGameProps() {
    for (var p in List.of(_gameProps)) {
      p.position += Offset(0, p.speed);
      if (p.position.dy > _screenSize.height) _gameProps.remove(p);
    }
  }

  /// 更新爆炸效果
  void _updateExplosions() {
    for (var e in List.of(_explosions)) {
      e.update();
      if (e.finished) _explosions.remove(e);
    }
  }

  /// 显示警报
  void showAlert(String text, Color color, AlertType type) {
    _alerts.add(GameAlert(text: text, color: color, type: type, duration: 90));
  }

  /// 更新警报状态
  void _updateAlerts() {
    for (var alert in List.of(_alerts)) {
      alert.timer++;

      // 前10帧快速显示
      if (alert.timer <= 10) {
        alert.opacity = alert.timer / 10;
      }
      // 后30帧开始淡化
      else if (alert.timer >= alert.duration - 30) {
        alert.opacity = (alert.duration - alert.timer) / 30;
      }

      if (alert.timer >= alert.duration) {
        _alerts.remove(alert);
      }
    }
  }

  /// 检测碰撞
  void _checkCollisions() {
    _checkBulletCollisions();
    _checkPlayerCollisions();
    _checkPropCollisions();
  }

  /// 检测子弹碰撞
  void _checkBulletCollisions() {
    for (var b in List.of(_bullets)) {
      // 敌人碰撞检测
      for (var e in List.of(_enemies)) {
        if (b.rect.overlaps(e.rect)) {
          _bullets.remove(b);
          e.health -= b.config.damage;

          if (e.health <= 0) {
            _enemies.remove(e);
            _score += e.points;
            _enemiesDestroyed++;

            _explosions.add(
              Explosion(
                position:
                    e.position + Offset(e.size.width / 2, e.size.height / 2),
                size: e.size.width * 1.5,
              ),
            );

            if (e.type == EnemyType.boss) {
              _spawnGameProp(_boss!.position, probability: 1);
              _boss = null;
              _levelUp();
            } else {
              _spawnGameProp(e.position);
            }

            if (_enemiesDestroyed % 15 == 0) _spawnBoss();
          }
          break;
        }
      }
    }
  }

  /// 检测玩家碰撞
  void _checkPlayerCollisions() {
    if (_player.invincible) return;

    for (var e in List.of(_enemies)) {
      if (_player.rect.overlaps(e.rect)) {
        if (e.type != EnemyType.boss) {
          _enemies.remove(e);
          _explosions.add(
            Explosion(
              position:
                  e.position + Offset(e.size.width / 2, e.size.height / 2),
              size: e.size.width * 1.5,
            ),
          );
        }
        if (_player.shield) {
          _player.shield = false;
        } else {
          _lives--;
          if (_lives <= 0) return _handleGameOver();
          _player.invincible = true;
          _player.invincibleTimer = 120;
        }
      }
    }
  }

  /// 检测道具碰撞
  void _checkPropCollisions() {
    for (var p in List.of(_gameProps)) {
      if (_player.rect.overlaps(p.rect)) {
        _gameProps.remove(p);

        switch (p.type) {
          case PropType.tripleShot:
            _player.tripleShot = true;
            _player.tripleShotTimer = 300;
            break;
          case PropType.shield:
            _player.shield = true;
            break;
          case PropType.flame:
            _player.flameBullet = true;
            _player.flameBulletTimer = 300;
            break;
          case PropType.bigBullet:
            _player.bigBullet = true;
            _player.bigBulletTimer = 300;
            break;
        }
      }
    }
  }

  /// 生成道具
  void _spawnGameProp(Offset position, {double probability = 0.25}) {
    if (_random.nextDouble() < probability) {
      PropType type;
      final rand = _random.nextDouble();

      if (rand < 0.3) {
        type = PropType.tripleShot;
      } else if (rand < 0.5) {
        type = PropType.shield;
      } else if (rand < 0.75) {
        type = PropType.flame;
      } else {
        type = PropType.bigBullet;
      }

      _gameProps.add(
        GameProp(
          position: position,
          size: const Size(25, 25),
          speed: 2,
          type: type,
          color: _getPropColor(type),
        ),
      );
    }
  }

  /// 获取道具颜色
  Color _getPropColor(PropType type) {
    switch (type) {
      case PropType.tripleShot:
        return Colors.cyan;
      case PropType.shield:
        return Colors.green;
      case PropType.flame:
        return Colors.orange;
      case PropType.bigBullet:
        return Colors.purple;
    }
  }

  /// 升级处理
  void _levelUp() {
    _level++;
    _disableKeyState();
    _gameState = GameState.levelUp;
    _enemies.clear();
    _boss = null;
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      _disableKeyState();
      _gameState = GameState.playing;
      notifyListeners();
    });
  }

  /// 射击
  void shoot() {
    if (_cooldown <= 0 && _gameState == GameState.playing) {
      // 确定子弹属性
      final bulletConfig = _getBulletConfig();

      if (_player.tripleShot) {
        _bullets.addAll([
          _createBullet(angle: 0, config: bulletConfig),
          _createBullet(angle: -15, config: bulletConfig),
          _createBullet(angle: 15, config: bulletConfig),
        ]);
      } else {
        _bullets.add(_createBullet(angle: 0, config: bulletConfig));
      }

      // 设置冷却时间
      _cooldown = _player.bigBullet ? 30 : 20;
    }
  }

  /// 获取子弹配置
  BulletConfig _getBulletConfig() {
    bool isBig = false;
    bool isFlame = false;
    Size bulletSize = const Size(4, 12);
    Color bulletColor = Colors.cyan;
    double damage = 1;

    if (_player.bigBullet) {
      isBig = true;
      bulletSize = const Size(8, 20);
      damage *= 1.5;
    }

    if (_player.flameBullet) {
      isFlame = true;
      bulletColor = Colors.orange;
      damage *= 2;
    }

    return BulletConfig(
      isBig: isBig,
      isFlame: isFlame,
      damage: damage,
      color: bulletColor,
      size: bulletSize,
    );
  }

  /// 创建子弹
  Bullet _createBullet({required double angle, required BulletConfig config}) {
    return Bullet(
      position:
          _player.position +
          Offset(_player.size.width / 2 - config.size.width / 2, 0),
      angle: angle,
      config: config,
    );
  }

  /// 处理拖拽移动
  void handleDrag(Offset delta) {
    if (_gameState == GameState.playing) {
      _player.position += delta;
      notifyListeners();
    }
  }

  /// 处理键盘事件
  void handleKeyEvent(KeyEvent event) {
    if (_gameState != GameState.playing) return;

    // 按键按下
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          _isUpPressed = true;
          break;
        case LogicalKeyboardKey.arrowDown:
          _isDownPressed = true;
          break;
        case LogicalKeyboardKey.arrowLeft:
          _isLeftPressed = true;
          break;
        case LogicalKeyboardKey.arrowRight:
          _isRightPressed = true;
          break;
        case LogicalKeyboardKey.space:
          _isSpacePressed = true;
          break;
        case LogicalKeyboardKey.keyP:
          pauseGame();
          break;
      }

      _handleLongPressActions();
    }

    // 按键抬起
    if (event is KeyUpEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          _isUpPressed = false;
          break;
        case LogicalKeyboardKey.arrowDown:
          _isDownPressed = false;
          break;
        case LogicalKeyboardKey.arrowLeft:
          _isLeftPressed = false;
          break;
        case LogicalKeyboardKey.arrowRight:
          _isRightPressed = false;
          break;
        case LogicalKeyboardKey.space:
          _isSpacePressed = false;
          break;
      }
    }
  }

  /// 开始游戏
  void startGame() {
    _score = 0;
    _lives = 3;
    _level = 1;
    _enemiesDestroyed = 0;
    _boss = null;
    _bullets.clear();
    _enemies.clear();
    _gameProps.clear();
    _explosions.clear();
    _resetPlayer();
    _disableKeyState();
    _gameState = GameState.playing;
    notifyListeners();
  }

  /// 暂停游戏
  void pauseGame() {
    if (_gameState == GameState.playing) {
      _disableKeyState();
      _gameState = GameState.paused;
      notifyListeners();
    }
  }

  /// 继续游戏
  void resumeGame() {
    if (_gameState == GameState.paused) {
      _disableKeyState();
      _gameState = GameState.playing;
      notifyListeners();
    }
  }

  /// 处理游戏结束
  void _handleGameOver() {
    _disableKeyState();
    _gameState = GameState.gameOver;
    notifyListeners();
  }

  /// 禁用所有按键状态
  void _disableKeyState() {
    _isUpPressed = false;
    _isDownPressed = false;
    _isLeftPressed = false;
    _isRightPressed = false;
    _isSpacePressed = false;
  }

  // Getters
  Size get screenSize => _screenSize;
  GameState get gameState => _gameState;
  int get score => _score;
  int get lives => _lives;
  int get level => _level;
  Player get player => _player;
  List<Star> get stars => _stars;
  List<Bullet> get bullets => _bullets;
  List<Enemy> get enemies => _enemies;
  List<GameProp> get gameProps => _gameProps;
  List<Explosion> get explosions => _explosions;
  List<GameAlert> get alerts => _alerts;
  bool get hasBoss => _boss != null;
  Enemy? get boss => _boss;
}
