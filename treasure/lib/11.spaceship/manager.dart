import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'base.dart';

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

  bool _isUpPressed = false; // 上键是否按下
  bool _isDownPressed = false; // 下键是否按下
  bool _isLeftPressed = false; // 左键是否按下
  bool _isRightPressed = false; // 右键是否按下
  bool _isSpacePressed = false; // 空格键是否按下

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  void initGame(Size size) {
    changeSize(size);
    _resetPlayer();
    _ticker = createTicker((_) => _update());
    _ticker.start();
  }

  void changeSize(Size size) {
    _screenSize = size;
    _createStars();
  }

  // 修改_update方法，添加BOSS更新逻辑
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

  void _resetPlayer() {
    _player = Player(
      position: Offset(_screenSize.width / 2 - 20, _screenSize.height - 70),
    );
  }

  void _updateStars() {
    for (var star in _stars) {
      star.position += Offset(0, star.speed);
      if (star.position.dy > _screenSize.height) {
        star.position = Offset(_random.nextDouble() * _screenSize.width, 0);
      }
    }
  }

  void _handleLongPressActions() {
    const double moveSpeed = 5.0; // 移动速度

    // 1. 处理方向键长按：根据按键状态持续移动玩家
    if (_isUpPressed) {
      _player.position += Offset(0, -moveSpeed);
    }
    if (_isDownPressed) {
      _player.position += Offset(0, moveSpeed);
    }
    if (_isLeftPressed) {
      _player.position += Offset(-moveSpeed, 0);
    }
    if (_isRightPressed) {
      _player.position += Offset(moveSpeed, 0);
    }

    // 2. 处理空格键长按：配合冷却实现连发（避免无限射击）
    if (_isSpacePressed && _cooldown <= 0) {
      shoot();
    }
  }

  void _updatePlayer() {
    _player.position = Offset(
      _player.position.dx.clamp(0, _screenSize.width - _player.size.width),
      _player.position.dy.clamp(0, _screenSize.height - _player.size.height),
    );

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

  void _updateBullets() {
    for (var b in List.of(_bullets)) {
      final rad = b.angle * 3.1415 / 180;
      b.position += Offset(sin(rad) * 7, -cos(rad) * 7);
      if (b.position.dy < -b.size.height) _bullets.remove(b);
    }
  }

  void _spawnEnemies() {
    if (hasBoss) return;
    _spawnTimer++;
    final rate = 100 - (_level - 1) * 5;
    if (_spawnTimer >= rate) {
      _spawnTimer = 0;
      final type = _random.nextDouble();
      late Enemy enemy;
      if (type < 0.6) {
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
        );
      } else if (type < 0.9) {
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
          points: 20,
        );
      }
      _enemies.add(enemy);
    }
  }

  void _updateEnemies() {
    for (var e in List.of(_enemies)) {
      if (e.type == EnemyType.boss) {
        continue;
      }

      e.position += Offset(e.dx ?? 0, e.speed);
      if (e.type == EnemyType.fast && e.dx != null) {
        if (e.position.dx < 0 ||
            e.position.dx > _screenSize.width - e.size.width) {
          e.dx = -e.dx!;
        }
      }
      if (e.position.dy > _screenSize.height) {
        _enemies.remove(e);
        // fast类型的敌人当作敌人的子弹处理
        if (e.type != EnemyType.fast) {
          _score = (_score - 5).clamp(0, double.infinity).toInt();
          // 显示敌人逃脱警报
          showAlert("敌人逃脱!", Colors.red, AlertType.enemyEscaped);
        }
      }
    }
  }

  // 添加显示警报的方法
  void showAlert(String text, Color color, AlertType type) {
    _alerts.add(GameAlert(text: text, color: color, type: type, duration: 90));
  }

  // 添加更新警报的方法
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

  // 添加BOSS生成方法
  void _spawnBoss() {
    if (hasBoss) return;

    _boss = Enemy(
      type: EnemyType.boss,
      position: Offset(
        _screenSize.width / 2 - 60, // 居中位置
        -60, // 从屏幕顶部外开始
      ),
      size: const Size(60, 60), // 大型尺寸
      speed: 1.5, // 移动速度
      health: 9 + (_level - 1) * 3, // 初始9血，每级+3
      color: Colors.redAccent,
      points: 20, // 高分值
      dx: 2.0, // 左右移动速度
      isMovingDown: true,
    );
    _enemies.add(_boss!);
    showAlert("BOSS出现!", Colors.redAccent, AlertType.warning);
  }

  // 添加BOSS更新方法
  void _updateBoss() {
    if (_boss == null) return;

    // BOSS移动逻辑：先向下到中间，然后左右移动
    if (_boss!.isMovingDown) {
      _boss!.position += Offset(0, _boss!.speed);
      if (_boss!.position.dy >= _screenSize.height / 3) {
        _boss!.isMovingDown = false;
      }
    } else {
      // 左右移动，碰到边界反弹
      if (_boss!.dx != null) {
        _boss!.position += Offset(_boss!.dx!, 0);
        if (_boss!.position.dx < 0 ||
            _boss!.position.dx > _screenSize.width - _boss!.size.width) {
          _boss!.dx = -_boss!.dx!;
        }
      }
    }

    // BOSS生成小敌人（fast类型）
    _boss!.minionSpawnTimer++;
    if (_boss!.minionSpawnTimer >= 120) {
      // 每2秒生成一个
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

  void _updateGameProps() {
    for (var p in List.of(_gameProps)) {
      p.position += Offset(0, p.speed);
      if (p.position.dy > _screenSize.height) _gameProps.remove(p);
    }
  }

  void _updateExplosions() {
    for (var e in List.of(_explosions)) {
      e.update();
      if (e.finished) _explosions.remove(e);
    }
  }

  void _checkCollisions() {
    for (var b in List.of(_bullets)) {
      if (hasBoss) {
        if (b.rect.overlaps(_boss!.rect)) {
          _bullets.remove(b);
          _boss!.health -= b.damage;
          if (_boss!.health <= 0) {
            _score += _boss!.points;
            _spawnGameProp(_boss!.position, probability: 1);
            _enemies.remove(_boss!);
            _boss = null;
            _levelUp();
          }
        }
      }

      for (var e in List.of(_enemies)) {
        if (b.rect.overlaps(e.rect)) {
          _bullets.remove(b);

          e.health -= b.damage;
          if (e.health <= 0) {
            _enemies.remove(e);
            _score += e.points;
            if (!hasBoss) {
              _enemiesDestroyed++;
            }
            _explosions.add(
              Explosion(
                position:
                    e.position + Offset(e.size.width / 2, e.size.height / 2),
                size: e.size.width * 1.5,
              ),
            );

            _spawnGameProp(e.position);
            if (_enemiesDestroyed % 15 == 0) _spawnBoss();
          }
          break;
        }
      }
    }

    if (!_player.invincible) {
      for (var e in List.of(_enemies)) {
        if (_player.rect.overlaps(e.rect)) {
          _enemies.remove(e);
          _explosions.add(
            Explosion(
              position:
                  e.position + Offset(e.size.width / 2, e.size.height / 2),
              size: e.size.width * 1.5,
            ),
          );
          if (_player.shield) {
            _player.shield = false;
          } else {
            _lives--;
            _player.invincible = true;
            _player.invincibleTimer = 120;
            if (_lives <= 0) {
              return _handleGameOver();
            }
          }
        }
      }
    }

    // 处理道具拾取
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
          case PropType.flame: // 火焰子弹道具效果
            _player.flameBullet = true;
            _player.flameBulletTimer = 300;
            break;
          case PropType.bigBullet: // 大子弹道具效果
            _player.bigBullet = true;
            _player.bigBulletTimer = 300;
            break;
        }
      }
    }
  }

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
          color: type == PropType.tripleShot
              ? Colors.cyan
              : type == PropType.shield
              ? Colors.green
              : type == PropType.flame
              ? Colors.orange
              : Colors.purple,
        ),
      );
    }
  }

  void _levelUp() {
    _level++;
    _disableKeyState();
    _gameState = GameState.levelUp;
    _enemies.clear();
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _disableKeyState();
      _gameState = GameState.playing;
      notifyListeners();
    });
  }

  void shoot() {
    if (_cooldown <= 0 && _gameState == GameState.playing) {
      // 确定子弹属性
      bool isBig = false;
      bool isFlame = false;
      Size bulletSize = const Size(4, 12);
      Color bulletColor = Colors.cyan;
      double damage = 1;

      // 应用大子弹效果
      if (_player.bigBullet) {
        isBig = true;
        bulletSize = const Size(8, 20);
        damage *= 1.5;
      }

      // 应用火焰子弹效果
      if (_player.flameBullet) {
        isFlame = true;
        bulletColor = Colors.orange;
        damage *= 2;
      }

      if (_player.tripleShot) {
        _bullets.addAll([
          Bullet(
            isBig: isBig,
            isFlame: isFlame,
            damage: damage,
            position:
                _player.position +
                Offset(_player.size.width / 2 - bulletSize.width / 2, 0),
            size: bulletSize,
            color: bulletColor,

            angle: 0,
          ),
          Bullet(
            isBig: isBig,
            isFlame: isFlame,
            damage: damage,
            position:
                _player.position +
                Offset(_player.size.width / 2 - bulletSize.width / 2, 0),
            size: bulletSize,
            color: bulletColor,
            angle: -15,
          ),
          Bullet(
            isBig: isBig,
            isFlame: isFlame,
            damage: damage,
            position:
                _player.position +
                Offset(_player.size.width / 2 - bulletSize.width / 2, 0),
            size: bulletSize,
            color: bulletColor,
            angle: 15,
          ),
        ]);
      } else {
        _bullets.add(
          Bullet(
            isBig: isBig,
            isFlame: isFlame,
            damage: damage,
            position:
                _player.position +
                Offset(_player.size.width / 2 - bulletSize.width / 2, 0),
            size: bulletSize,
            color: bulletColor,

            angle: 0,
          ),
        );
      }

      // 根据子弹类型调整冷却时间
      _cooldown = _player.bigBullet ? 30 : 20;
    }
  }

  void handleDrag(Offset delta) {
    if (_gameState == GameState.playing) {
      _player.position += delta;
      notifyListeners();
    }
  }

  void handleKeyEvent(KeyEvent event) {
    if (_gameState != GameState.playing) return;

    // 按键按下：标记对应状态为 true
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

    // 按键抬起：标记对应状态为 false
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

  void startGame() {
    _score = 0;
    _lives = 3;
    _level = 1;
    _enemiesDestroyed = 0;
    _bullets.clear();
    _enemies.clear();
    _gameProps.clear();
    _explosions.clear();
    _resetPlayer();
    _disableKeyState();
    _gameState = GameState.playing;
    notifyListeners();
  }

  void pauseGame() {
    if (_gameState == GameState.playing) {
      _disableKeyState();
      _gameState = GameState.paused;
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_gameState == GameState.paused) {
      _disableKeyState();
      _gameState = GameState.playing;
      notifyListeners();
    }
  }

  void _handleGameOver() {
    _disableKeyState();
    _gameState = GameState.gameOver;
    notifyListeners();
  }

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
