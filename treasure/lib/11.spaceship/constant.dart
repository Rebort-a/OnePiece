import 'package:flutter/material.dart';

// 游戏常量
class GameConstants {
  // 颜色常量
  static const Color bgColor = Color(0xFF0B1120);
  static const Color playerColor = Color(0xFF00F0FF);
  static const Color invincibleColor = Color(0x8000F0FF);
  static const Color shieldColor = Color(0x8000FF00);
  static const Color textNeonBlue = Color(0xFF00F0FF);
  static const Color textNeonBlueAlpha = Color(0xB300F0FF);
  static const Color textNeonPink = Color(0xFFFF00C8);
  static const Color bulletFlameColor = Colors.orange;
  static const Color textCyan = Colors.cyan;
  static const Color textYellow = Colors.yellow;
  static const Color textGreen = Colors.green;
  static const Color enemyBasicColor = Colors.red;
  static const Color enemyFastColor = Colors.yellow;
  static const Color enemyHeavyColor = Colors.purple;
  static const Color enemyBossColor = Colors.redAccent;
  static const Color bulletDefaultColor = Colors.cyan;

  // 尺寸常量
  static const Size playerSize = Size(40, 50);
  static const Size enemyBasicSize = Size(30, 30);
  static const Size enemyFastSize = Size(20, 20);
  static const Size enemyHeavySize = Size(40, 40);
  static const Size enemyBossSize = Size(60, 60);
  static const Size propSize = Size(25, 25);
  static const Size bulletNormalSize = Size(4, 12);
  static const Size bulletBigSize = Size(8, 20);

  // 游戏参数常量
  static const double playerMoveSpeed = 5.0;
  static const int playHealth = 50;
  static const int initialLevel = 1;
  static const int cooldownNormal = 20;
  static const int cooldownBig = 30;
  static const double bulletDamageNormal = 1;
  static const double bulletDamageBigMultiplier = 1.5;
  static const double bulletDamageFlameMultiplier = 2;
  static const int propEffectDuration = 600;
  static const int playerFlashDuration = 15;
  static const int invincibleDuration = 120;
  static const int levelUpDelay = 3000;
  static const int enemyEscapePenalty = 5;
  static const int shieldOffsetDamage = 30;

  // 文本样式常量
  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: textNeonBlue,
    shadows: [
      Shadow(color: textNeonBlueAlpha, offset: Offset(0, 0), blurRadius: 10),
      Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
    ],
  );

  static const TextStyle infoTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
    ],
  );

  static const TextStyle bannerTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textNeonPink,
    shadows: [Shadow(color: textNeonPink, blurRadius: 10)],
  );

  // 动画常量
  static const Duration alertDuration = Duration(milliseconds: 2000);
  static const Duration textDuration = Duration(milliseconds: 1000);
  static const Duration achieveDuration = Duration(milliseconds: 3000);
}

// 成就类型
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

// 成就配置
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

// 所有成就列表
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
