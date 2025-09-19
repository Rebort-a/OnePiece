import 'package:flutter/material.dart';

/// 游戏常量统一管理
/// 按功能模块划分，仅包含实际使用的常量

// ------------------------------ 颜色常量 ------------------------------
class ColorConstants {
  // 基础色调
  static const Color backgroundColor = Color(0xFF0B1120); // 游戏背景色（深色星空）
  static const Color playerColor = Color(0xFF00F0FF); // 玩家飞船主色（青色）
  static const Color invincibleColor = Color(0x8000F0FF); // 玩家无敌状态色（半透青色）
  static const Color shieldColor = Color(0x8000FF00); // 护盾效果色（半透绿色）

  // 文本颜色
  static const Color textNeonBlue = Color(0xFF00F0FF); // 霓虹蓝文本（标题）
  static const Color textNeonBlueAlpha = Color(0xB300F0FF); // 半透霓虹蓝（标题阴影）
  static const Color textNeonPink = Color(0xFFFF00C8); // 霓虹粉文本（爆炸、警告）
  static const Color textCyan = Colors.cyan; // 青色文本（生命值显示）
  static const Color textYellow = Colors.yellow; // 黄色文本（分数显示）
  static const Color textGreen = Colors.green; // 绿色文本（等级显示）

  // 敌人颜色
  static const Color enemyBasic = Colors.red; // 基础敌人（三角形）
  static const Color enemyFast = Colors.yellow; // 快速敌人（菱形）
  static const Color enemyHeavy = Colors.purple; // 重型敌人（矩形）
  static const Color enemyBoss = Colors.redAccent; // BOSS敌人（六边形）

  // 子弹颜色
  static const Color bulletDefault = Colors.cyan; // 普通子弹
  static const Color bulletFlame = Colors.orange; // 火焰子弹
}

// ------------------------------ 尺寸常量 ------------------------------
class SizeConstants {
  // 玩家相关
  static const Size player = Size(40, 50); // 玩家飞船尺寸

  // 敌人相关
  static const Size enemyBasic = Size(30, 30); // 基础敌人尺寸
  static const Size enemyFast = Size(20, 20); // 快速敌人尺寸
  static const Size enemyHeavy = Size(40, 40); // 重型敌人尺寸
  static const Size enemyBoss = Size(60, 60); // BOSS敌人尺寸

  // 道具相关
  static const Size prop = Size(25, 25); // 道具通用尺寸

  // 子弹相关
  static const Size bulletNormal = Size(4, 12); // 普通子弹尺寸
  static const Size bulletBig = Size(8, 20); // 大子弹尺寸

  // UI元素
  static const double hudPadding = 16.0; // HUD元素内边距
  static const double buttonSize = 50.0; // 按钮尺寸
}

// ------------------------------ 游戏核心参数 ------------------------------
class ParamConstants {
  // 玩家属性
  static const int playerInitialHealth = 50; // 初始生命值
  static const double playerMoveSpeed = 10.0; // 移动速度
  static const double touchSensitivity = 0.5; // 触摸灵敏度系数
  static const int invincibleDuration = 120; // 无敌状态持续帧数（约2秒）
  static const int playerFlashDuration = 15; // 无敌闪烁间隔帧数

  // 敌人属性
  static const int enemyBaseHealth = 5; // 基础/快速敌人初始生命值
  static const int enemyHeavyHealth = 30; // 重型敌人初始生命值
  static const int enemyEscapePenalty = 5; // 敌人逃脱扣分
  static const int shieldOffsetDamage = 30; // 护盾碰撞时对敌人的伤害

  // BOSS属性
  static const int bossInitialHealth = 100; // BOSS初始生命值
  static const int bossHealthPerLevel = 20; // 每级增加的BOSS生命值

  // 子弹属性
  static const int bulletBaseDamage = 10; // 基础子弹伤害
  static const double bulletSpeed = 8.0; // 子弹飞行速度
  static const int bulletCooldown = 20; // 射击冷却帧数
  static const double bulletBigMultiplier = 1.5; // 大子弹伤害倍率
  static const int bulletFlameMultiplier = 2; // 火焰子弹伤害倍率
  static const int bigCooldown = 30; // 大子弹射击冷却帧数

  // 道具属性
  static const int propEffectDuration = 600; // 道具效果持续帧数（约10秒）
  static const double propDropRateBasic = 0.25; // 基础敌人道具掉落率
  static const double propDropRateHeavy = 0.5; // 重型敌人道具掉落率
  static const double propDropRateBoss = 1.0; // BOSS道具掉落率

  // 关卡与生成
  static const int initialLevel = 1; // 初始等级
  static const int enemyCountPerBoss = 10; // 每关需要击杀的敌人数(基础+重型)
  static const int enemyCountPerBossIncrement = 5; // 每级增加的BOSS触发敌人数
  static const int levelUpDelay = 3000; // 等级提升提示持续毫秒数

  // 星星背景
  static const int starCount = 100; // 背景星星数量
  static const double minStarSpeed = 1.0; // 星星最小移动速度
  static const double maxStarSpeed = 3.0; // 星星最大移动速度
}

// ------------------------------ 文本样式 ------------------------------
class TextStyleConstants {
  // 标题样式（如"星际战机"）
  static const TextStyle title = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: ColorConstants.textNeonBlue,
    shadows: [
      Shadow(
        color: ColorConstants.textNeonBlueAlpha,
        offset: Offset(0, 0),
        blurRadius: 10,
      ),
      Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
    ],
  );

  // 信息文本样式（生命值、分数、等级）
  static const TextStyle info = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 4),
    ],
  );

  // 横幅文本样式（如"Boss出现"、"敌人逃脱"）
  static const TextStyle banner = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: ColorConstants.textNeonPink,
    shadows: [Shadow(color: ColorConstants.textNeonPink, blurRadius: 10)],
  );

  // 按钮文本样式
  static const TextStyle button = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

// ------------------------------ 动画与显示时长 ------------------------------
class DurationConstants {
  static const Duration alert = Duration(milliseconds: 2000); // 警告横幅显示时长
  static const Duration text = Duration(milliseconds: 1000); // 普通文本提示时长
  static const Duration achievement = Duration(milliseconds: 3000); // 成就解锁提示时长
  static const Duration explosion = Duration(milliseconds: 500); // 爆炸动画时长
}
