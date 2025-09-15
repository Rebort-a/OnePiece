import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'base.dart';

class Manager with ChangeNotifier implements TickerProvider {
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

  void _update() {
    if (_gameState == GameState.playing) {
      _updateStars();
      _handleLongPressActions();
      _updatePlayer();
      _updateBullets();
      _spawnEnemies();
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
            Random().nextDouble() * _screenSize.width,
            Random().nextDouble() * _screenSize.height,
          ),
          size: Size.square(Random().nextDouble() * 1.5),
          opacity: Random().nextDouble(),
          speed: Random().nextDouble() * 0.5 + 0.1,
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
        star.position = Offset(Random().nextDouble() * _screenSize.width, 0);
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
    _spawnTimer++;
    final rate = 60 - (_level - 1) * 5;
    if (_spawnTimer >= rate) {
      _spawnTimer = 0;
      final type = Random().nextDouble();
      late Enemy enemy;
      if (type < 0.6) {
        enemy = Enemy(
          type: EnemyType.basic,
          position: Offset(
            Random().nextDouble() * (_screenSize.width - 30),
            -30,
          ),
          size: const Size(30, 30),
          speed: 2 + (_level - 1) * 0.3,
          health: 1,
          color: Colors.red,
          points: 10,
        );
      } else if (type < 0.9) {
        enemy = Enemy(
          type: EnemyType.fast,
          position: Offset(
            Random().nextDouble() * (_screenSize.width - 20),
            -20,
          ),
          size: const Size(20, 20),
          speed: 4 + (_level - 1) * 0.5,
          health: 1,
          color: Colors.yellow,
          points: 5,
          dx: (Random().nextDouble() - 0.5) * 2,
        );
      } else {
        enemy = Enemy(
          type: EnemyType.heavy,
          position: Offset(
            Random().nextDouble() * (_screenSize.width - 40),
            -40,
          ),
          size: const Size(40, 40),
          speed: 1 + (_level - 1) * 0.2,
          health: 3,
          color: Colors.purple,
          points: 20,
        );
      }
      _enemies.add(enemy);
    }
  }

  void _updateEnemies() {
    for (var e in List.of(_enemies)) {
      e.position += Offset(e.dx ?? 0, e.speed);
      if (e.type == EnemyType.fast && e.dx != null) {
        if (e.position.dx < 0 ||
            e.position.dx > _screenSize.width - e.size.width) {
          e.dx = -e.dx!;
        }
      }
      if (e.position.dy > _screenSize.height) {
        _enemies.remove(e);
        _score = (_score - 5).clamp(0, double.infinity).toInt();
        // 显示敌人逃脱警报
        showAlert("敌人逃脱！", Colors.red, AlertType.enemyEscaped);
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
      for (var e in List.of(_enemies)) {
        if (b.rect.overlaps(e.rect)) {
          _bullets.remove(b);
          int damage = b.type == BulletType.flame ? 2 : 1;
          e.health -= damage;
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
            _spawnGameProp(e.position);
            if (_enemiesDestroyed % 10 == 0) _levelUp();
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
              _gameState = GameState.gameOver;
              notifyListeners();
              return;
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

  void _spawnGameProp(Offset position) {
    if (Random().nextDouble() < 0.25) {
      PropType type;
      final rand = Random().nextDouble();
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
    _gameState = GameState.levelUp;
    _enemies.clear();
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _gameState = GameState.playing;
      notifyListeners();
    });
  }

  void shoot() {
    if (_cooldown <= 0 && _gameState == GameState.playing) {
      // 确定子弹属性
      BulletType bulletType = BulletType.normal;
      Size bulletSize = const Size(4, 12);
      Color bulletColor = Colors.cyan;

      // 应用大子弹效果
      if (_player.bigBullet) {
        bulletType = BulletType.big;
        bulletSize = const Size(8, 20);
        bulletColor = Colors.purple;
      }
      // 应用火焰子弹效果
      else if (_player.flameBullet) {
        bulletType = BulletType.flame;
        bulletColor = Colors.orange;
      }

      if (_player.tripleShot) {
        _bullets.addAll([
          Bullet(
            position:
                _player.position +
                Offset(_player.size.width / 2 - bulletSize.width / 2, 0),
            size: bulletSize,
            color: bulletColor,
            type: bulletType,
            angle: 0,
          ),
          Bullet(
            position:
                _player.position +
                Offset(_player.size.width / 2 - bulletSize.width / 2, 0),
            size: bulletSize,
            color: bulletColor,
            angle: -15,
            type: bulletType,
          ),
          Bullet(
            position:
                _player.position +
                Offset(_player.size.width / 2 - bulletSize.width / 2, 0),
            size: bulletSize,
            color: bulletColor,
            angle: 15,
            type: bulletType,
          ),
        ]);
      } else {
        _bullets.add(
          Bullet(
            position:
                _player.position +
                Offset(_player.size.width / 2 - bulletSize.width / 2, 0),
            size: bulletSize,
            color: bulletColor,
            type: bulletType,
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
    _gameState = GameState.playing;
    notifyListeners();
  }

  void pauseGame() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      notifyListeners();
    }
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
}
