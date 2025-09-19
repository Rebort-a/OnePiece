import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../00.common/component/template_dialog.dart';
import '../00.common/tool/notifier.dart';
import 'base.dart';
import 'constant.dart';

/// 游戏状态枚举
enum GameState { start, playing, paused, gameOver, levelUp }

/// 游戏管理器
class Manager with ChangeNotifier implements TickerProvider {
  final Random _random = Random();
  late Ticker _ticker;
  Size _screenSize = Size.zero;
  GameState _gameState = GameState.start;
  Player _player = Player(
    color: GameConstants.playerColor,
    health: GameConstants.playHealth,
    speed: GameConstants.playerMoveSpeed,
  );

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});

  final List<Bullet> _bullets = [];
  final List<Enemy> _enemies = [];
  final List<GameProp> _gameProps = [];
  final List<Explosion> _explosions = [];
  final List<Star> _stars = [];

  int _score = 0;
  int _level = GameConstants.initialLevel;
  int _consecutiveKills = 0;
  int _enemiesDestroyed = 0;
  int _spawnTimer = 0;
  int _cooldown = 0;

  // 成就相关
  final Set<AchievementType> _unlockedAchievements = {};

  // 按键状态
  bool _isUpPressed = false;
  bool _isDownPressed = false;
  bool _isLeftPressed = false;
  bool _isRightPressed = false;
  bool _isSpacePressed = false;

  final FocusNode focusNode = FocusNode();

  Enemy? _boss;

  //  getter
  Size get screenSize => _screenSize;
  GameState get gameState => _gameState;
  Player get player => _player;
  List<Bullet> get bullets => List.unmodifiable(_bullets);
  List<Enemy> get enemies => List.unmodifiable(_enemies);
  List<GameProp> get gameProps => List.unmodifiable(_gameProps);
  List<Explosion> get explosions => List.unmodifiable(_explosions);
  List<Star> get stars => List.unmodifiable(_stars);
  int get score => _score;
  int get lives => _player.health;
  int get level => _level;
  bool get hasBoss => _boss != null;
  Set<AchievementType> get unlockedAchievements =>
      Set.unmodifiable(_unlockedAchievements);

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  /// 初始化游戏
  void initGame(Size size) {
    changeSize(size);
    _resetPlayer();
    _initTicker();
    _initFocusNote();
  }

  /// 改变屏幕尺寸
  void changeSize(Size size) {
    if (_screenSize != size) {
      _screenSize = size;
      _createStars();
      _keepPlayerInBounds();
    }
  }

  void _initTicker() {
    _ticker = createTicker((_) => _update());
    _ticker.start();
  }

  void _initFocusNote() {
    focusNode.requestFocus();
  }

  /// 创建星空背景
  void _createStars() {
    _stars.clear();
    final count = (_screenSize.width * _screenSize.height / 1000).toInt();
    for (int i = _stars.length; i < count; i++) {
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

  // bool _isOnScreen(GameObject object) {
  //   return object.position.dx >= 0 && // 左边界
  //       object.position.dx + object.size.width <= screenSize.width && // 右边界
  //       object.position.dy >= 0 && // 上边界
  //       object.position.dy + object.size.height <= screenSize.height; // 下边界
  // }

  /// 确保玩家在边界内
  void _keepPlayerInBounds() {
    double x = _player.position.dx;
    double y = _player.position.dy;

    x = x.clamp(0, _screenSize.width - _player.size.width);
    y = y.clamp(0, _screenSize.height - _player.size.height);

    _player.position = Offset(x, y);
  }

  /// 重置玩家
  void _resetPlayer() {
    _player = Player(
      position: Offset(
        _screenSize.width / 2 - GameConstants.playerSize.width / 2,
        _screenSize.height - GameConstants.playerSize.height - 20,
      ),
      size: GameConstants.playerSize,
      color: GameConstants.playerColor,
      health: GameConstants.playHealth,
      speed: GameConstants.playerMoveSpeed,
    );
  }

  /// 开始游戏
  void startGame() {
    _resetGame();
    resumeGame();
  }

  /// 重置游戏
  void _resetGame() {
    _score = 0;
    _level = GameConstants.initialLevel;
    _resetPlayer();
    _enemiesDestroyed = 0;
    _consecutiveKills = 0;

    _bullets.clear();
    _clearEnemies();
    _gameProps.clear();
    _explosions.clear();
    _unlockedAchievements.clear();
  }

  void _clearEnemies() {
    _enemies.clear();
    _boss = null;
  }

  /// 暂停游戏
  void pauseGame() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      notifyListeners();
    }
  }

  /// 恢复游戏
  void resumeGame() {
    _gameState = GameState.playing;
    notifyListeners();
  }

  /// 游戏结束
  void _gameOver() {
    _gameState = GameState.gameOver;
    notifyListeners();
  }

  /// 关卡升级
  void _levelUp() {
    _level++;
    _gameState = GameState.levelUp;
    notifyListeners();

    // 3秒后继续游戏
    Future.delayed(
      const Duration(milliseconds: GameConstants.levelUpDelay),
      () {
        resumeGame();
      },
    );
  }

  /// 检测并解锁成就
  void _checkAchievements() {
    // 首次击杀
    if (_enemiesDestroyed >= 1 &&
        !_unlockedAchievements.contains(AchievementType.firstKill)) {
      _unlockAchievement(AchievementType.firstKill);
    }

    // 得分成就
    if (_score >= 100 &&
        !_unlockedAchievements.contains(AchievementType.score100)) {
      _unlockAchievement(AchievementType.score100);
    }
    if (_score >= 500 &&
        !_unlockedAchievements.contains(AchievementType.score500)) {
      _unlockAchievement(AchievementType.score500);
    }
    if (_score >= 1000 &&
        !_unlockedAchievements.contains(AchievementType.score1000)) {
      _unlockAchievement(AchievementType.score1000);
    }

    // 等级成就
    if (_level >= 5 &&
        !_unlockedAchievements.contains(AchievementType.level5)) {
      _unlockAchievement(AchievementType.level5);
    }
    if (_level >= 10 &&
        !_unlockedAchievements.contains(AchievementType.level10)) {
      _unlockAchievement(AchievementType.level10);
    }

    // 三连杀
    if (_consecutiveKills >= 3 &&
        !_unlockedAchievements.contains(AchievementType.tripleKill)) {
      _unlockAchievement(AchievementType.tripleKill);
    }
  }

  /// 解锁成就
  void _unlockAchievement(AchievementType type) {
    if (!_unlockedAchievements.contains(type)) {
      _unlockedAchievements.add(type);
      final achievement = Achievements.all.firstWhere((a) => a.type == type);

      pageNavigator.value = (context) {
        TemplateDialog.achieveBanner(
          context: context,
          title: achievement.title,
          description: achievement.description,
          duration: GameConstants.achieveDuration,
        );
      };
    }
  }

  /// 处理拖动
  void handleDrag(Offset delta) {
    if (_gameState != GameState.playing) return;

    _player.position += Offset(delta.dx * 0.5, delta.dy * 0.5);
    _keepPlayerInBounds();
    notifyListeners();
  }

  /// 处理键盘事件
  void handleKeyEvent(KeyEvent event) {
    if (_gameState == GameState.start || _gameState == GameState.gameOver) {
      return;
    }

    final isKeyDown = event is KeyDownEvent;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _isUpPressed = isKeyDown;
        break;
      case LogicalKeyboardKey.arrowDown:
        _isDownPressed = isKeyDown;
        break;
      case LogicalKeyboardKey.arrowLeft:
        _isLeftPressed = isKeyDown;
        break;
      case LogicalKeyboardKey.arrowRight:
        _isRightPressed = isKeyDown;
        break;
      case LogicalKeyboardKey.space:
        _isSpacePressed = isKeyDown;
        break;
      case LogicalKeyboardKey.keyP:
        if (isKeyDown) {
          if (_gameState == GameState.playing) {
            pauseGame();
          } else {
            resumeGame();
          }
        }
        break;
    }

    if (isKeyDown) {
      _handleLongPressActions();
    }
  }

  /// 处理长按操作
  void _handleLongPressActions() {
    if (_gameState != GameState.playing) return;
    double moveSpeed = _player.speed;

    // 方向键移动
    if (_isUpPressed) _player.position += Offset(0, -moveSpeed);
    if (_isDownPressed) _player.position += Offset(0, moveSpeed);
    if (_isLeftPressed) _player.position += Offset(-moveSpeed, 0);
    if (_isRightPressed) _player.position += Offset(moveSpeed, 0);

    // 空格键射击
    if (_isSpacePressed) shoot();
  }

  /// 射击
  void shoot() {
    if (_cooldown <= 0) {
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
    int damage = 10;

    if (_player.bigBullet) {
      isBig = true;
      bulletSize = const Size(8, 20);
      damage = (damage * 1.5).round();
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

  /// 生成道具
  void _spawnGameProp(Offset position, double probability) {
    if (probability <= 0) return;

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
          size: GameConstants.propSize,
          speed: 2,
          type: type,
        ),
      );
    }
  }

  /// 生成敌人
  void _spawnEnemies() {
    _spawnTimer++;
    final rate = 100 - (_level - 1) * 5;

    if (_spawnTimer >= rate) {
      _spawnTimer = 0;
      final type = _random.nextDouble();
      late Enemy enemy;

      if (type < 0.6) {
        // 基础敌人
        enemy = Enemy(
          position: Offset(
            _random.nextDouble() *
                (_screenSize.width - GameConstants.enemyBasicSize.width),
            -GameConstants.enemyBasicSize.height,
          ),
          size: GameConstants.enemyBasicSize,
          type: EnemyType.basic,
          color: GameConstants.enemyBasicColor,
          health: 5 + _random.nextInt(10),
          speed: 2 + (_level - 1) * 0.3,
          dx: 0,
          points: 10,
          probability: 0.25,
        );
      } else if (type < 0.9) {
        // 快速敌人
        enemy = Enemy(
          position: Offset(
            _random.nextDouble() *
                (_screenSize.width - GameConstants.enemyFastSize.width),
            -GameConstants.enemyFastSize.height,
          ),
          size: GameConstants.enemyFastSize,
          type: EnemyType.fast,
          color: GameConstants.enemyFastColor,
          health: 5,
          speed: 4 + (_level - 1) * 0.5,
          dx: (_random.nextDouble() - 0.5) * 2,
          points: 5,
          probability: 0,
        );
      } else {
        // 重型敌人
        enemy = Enemy(
          position: Offset(
            _random.nextDouble() *
                (_screenSize.width - GameConstants.enemyHeavySize.width),
            -GameConstants.enemyHeavySize.height,
          ),
          size: GameConstants.enemyHeavySize,
          type: EnemyType.heavy,
          color: GameConstants.enemyHeavyColor,
          health: 30,
          speed: 1 + (_level - 1) * 0.2,
          dx: 0,
          points: 15,
          probability: 0.5,
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

      if (e.type == EnemyType.fast) {
        if (e.position.dx < 0 ||
            e.position.dx > _screenSize.width - e.size.width) {
          e.dx = -e.dx;
        }
      }

      // 敌人逃出屏幕
      if (e.position.dy > _screenSize.height) {
        _enemies.remove(e);
        if (e.type != EnemyType.fast) {
          _score = (_score - GameConstants.enemyEscapePenalty)
              .clamp(0, double.infinity)
              .toInt();
          _consecutiveKills = 0;
          // 显示敌人逃脱信息
          pageNavigator.value = (context) {
            TemplateDialog.textBanner(
              context: context,
              text: "敌人逃脱！",
              duration: GameConstants.textDuration,
            );
          };
        }
      }
    }
  }

  /// 生成BOSS
  void _spawnBoss() {
    if (hasBoss) return;

    // 使用AlertBanner显示BOSS出现信息
    pageNavigator.value = (context) {
      TemplateDialog.alertBanner(
        context: context,
        text: "Boss出现！",
        duration: GameConstants.alertDuration,
      );
    };
    _boss = Enemy(
      position: Offset(
        _screenSize.width / 2 - GameConstants.enemyBossSize.width / 2,
        -GameConstants.enemyBossSize.height,
      ),
      size: GameConstants.enemyBossSize,
      type: EnemyType.boss,
      color: GameConstants.enemyBossColor,
      health: 100 + (_level - 1) * 20,
      speed: 1.5,
      dx: _random.nextBool()
          ? _random.nextDouble() * 2 + 1
          : _random.nextDouble() * 2 - 3,
      points: 20,
      probability: 1,
    );

    _enemies.add(_boss!);
  }

  /// 更新BOSS状态
  void _updateBoss() {
    // BOSS移动逻辑
    if (_boss!.position.dy < _screenSize.height / 3) {
      // 如果未达到屏幕高度的1/3，则向下移动
      _boss!.position += Offset(0, _boss!.speed);
    } else {
      // 左右移动，碰到边界反弹
      _boss!.position += Offset(_boss!.dx, 0);
      if (_boss!.position.dx < 0 ||
          _boss!.position.dx > _screenSize.width - _boss!.size.width) {
        _boss!.dx = -_boss!.dx;
      }
    }

    // BOSS生成小敌人
    _spawnTimer++;
    final rate = 120 - (_level - 1) * 5;
    if (_spawnTimer >= rate) {
      _spawnTimer = 0;
      _enemies.add(
        Enemy(
          position: Offset(
            _boss!.position.dx + _boss!.size.width / 2 - 10,
            _boss!.position.dy + _boss!.size.height / 2,
          ),
          size: const Size(20, 20),
          type: EnemyType.fast,
          color: Colors.yellow,
          health: 5,
          speed: 4 + (_level - 1) * 0.5,
          dx: (_random.nextDouble() - 0.5) * 2,
          points: 5,
          probability: 0,
        ),
      );
    }
  }

  /// 更新子弹位置
  void _updateBullets() {
    if (_gameState != GameState.playing) return;

    for (var b in List.of(_bullets)) {
      final rad = b.angle * pi / 180;
      b.position += Offset(sin(rad) * 7, -cos(rad) * 7);

      // 移除超出屏幕的子弹
      if (b.position.dy < -b.config.size.height) {
        _bullets.remove(b);
      }
    }

    // 更新冷却时间
    if (_cooldown > 0) {
      _cooldown--;
    }
  }

  /// 更新星空
  void _updateStars() {
    for (var star in _stars) {
      star.position += Offset(0, star.speed);
      if (star.position.dy > _screenSize.height) {
        star.position = Offset(_random.nextDouble() * _screenSize.width, 0);
      }
    }
  }

  /// 更新道具
  void _updateProps() {
    if (_gameState != GameState.playing) return;

    for (var p in List.of(_gameProps)) {
      p.position += Offset(0, p.speed);

      if (p.position.dy > _screenSize.height) {
        _gameProps.remove(p);
      }
    }
  }

  /// 更新爆炸效果
  void _updateExplosions() {
    for (var e in List.of(_explosions)) {
      e.update();
      if (e.finished) {
        _explosions.remove(e);
      }
    }
  }

  /// 更新玩家状态
  void _updatePlayer() {
    // 更新冷却和状态计时器

    if (_player.tripleShot) {
      _player.tripleShotTimer--;
    }

    if (_player.flameBullet) {
      _player.flameBulletTimer--;
    }

    if (_player.bigBullet) {
      _player.bigBulletTimer--;
    }

    if (_player.invincible) {
      _player.invincibleTimer--;
      if (_player.invincible) {
        _player.flashTimer++;
        if (_player.flashTimer >= GameConstants.playerFlashDuration) {
          _player.flash = !_player.flash;
          _player.flashTimer = 0;
        }
      } else {
        _player.flash = false;
        _player.flashTimer = 0;
      }
    }
  }

  /// 检测子弹碰撞
  void _checkBulletCollisions() {
    if (_gameState != GameState.playing) return;

    for (var b in List.of(_bullets)) {
      // 敌人碰撞检测
      for (var e in List.of(_enemies)) {
        if (b.rect.overlaps(e.rect)) {
          _bullets.remove(b);
          _deductEnemyHealth(e, b.config.damage);
        }
      }
    }
  }

  void _deductEnemyHealth(Enemy enemy, int damage) {
    enemy.health -= damage;
    if (enemy.health <= 0) {
      _enemies.remove(enemy);
      _score += enemy.points;

      _explosions.add(
        Explosion(
          position:
              enemy.position +
              Offset(enemy.size.width / 2, enemy.size.height / 2),
          size: enemy.size.width * 1.5,
        ),
      );

      _spawnGameProp(enemy.position, enemy.probability);

      if (enemy.type == EnemyType.boss) {
        _boss = null;
        _levelUp();
        // BOSS击杀成就
        if (!_unlockedAchievements.contains(AchievementType.bossKill)) {
          _unlockAchievement(AchievementType.bossKill);
        }
      } else if (enemy.type != EnemyType.fast) {
        _enemiesDestroyed++;

        if (_enemiesDestroyed >= (10 + 5 * _level)) {
          _enemiesDestroyed = 0;
          _spawnBoss();
        }
        _consecutiveKills++;
      }

      // 检查成就
      _checkAchievements();
    }
  }

  /// 检测玩家与敌人碰撞
  void _checkPlayerCollisions() {
    if (_player.invincible) return;

    for (var e in List.of(_enemies)) {
      if (_player.rect.overlaps(e.rect)) {
        // 检查护盾
        if (_player.shield) {
          _player.shield = false;
          _deductEnemyHealth(e, GameConstants.shieldOffsetDamage);
        } else {
          // 重置连续击杀计数器
          _consecutiveKills = 0;
          int enemyHealth = e.health;
          _deductEnemyHealth(e, _player.health);
          _deductPlayerHealth(enemyHealth);
        }
      }
    }
  }

  void _deductPlayerHealth(int damage) {
    _player.health -= damage;
    if (_player.health <= 0) {
      _gameOver();
    } else {
      _player.invincibleTimer = GameConstants.invincibleDuration;
      _player.flash = true;
    }
  }

  /// 检测玩家与道具碰撞
  void _checkPropCollisions() {
    if (_gameState != GameState.playing) return;

    for (var p in List.of(_gameProps)) {
      if (_player.rect.overlaps(p.rect)) {
        _gameProps.remove(p);

        // 应用道具效果
        switch (p.type) {
          case PropType.tripleShot:
            _player.tripleShotTimer = GameConstants.propEffectDuration;
            break;
          case PropType.shield:
            _player.shield = true;
            break;
          case PropType.flame:
            _player.flameBulletTimer = GameConstants.propEffectDuration;
            break;
          case PropType.bigBullet:
            _player.bigBulletTimer = GameConstants.propEffectDuration;
            break;
        }
      }
    }
  }

  /// 更新游戏状态
  void _update() {
    if (_gameState == GameState.playing) {
      _updateStars();
      _updatePlayer();
      _updateBullets();
      if (hasBoss) {
        _updateBoss();
      } else {
        _spawnEnemies();
      }
      _updateEnemies();
      _updateProps();
      _updateExplosions();

      _checkBulletCollisions();
      _checkPlayerCollisions();
      _checkPropCollisions();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
