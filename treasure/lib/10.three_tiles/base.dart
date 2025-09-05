/// 3TILES游戏基础数据定义
enum CardType {
  sheep,
  grass,
  tree,
  flower,
  cloud,
  sun,
  moon,
  star,
  mountain,
  river,
  house,
  fence,
  carrot,
  wheat,
  mushroom,
}

/// 卡片扩展方法
extension CardTypeExt on CardType {
  /// 获取卡片对应的emoji
  String get emoji {
    switch (this) {
      case CardType.sheep:
        return "🐑";
      case CardType.grass:
        return "🌱";
      case CardType.tree:
        return "🌳";
      case CardType.flower:
        return "🌸";
      case CardType.cloud:
        return "☁️";
      case CardType.sun:
        return "☀️";
      case CardType.moon:
        return "🌙";
      case CardType.star:
        return "⭐";
      case CardType.mountain:
        return "⛰️";
      case CardType.river:
        return "🌊";
      case CardType.house:
        return "🏠";
      case CardType.fence:
        return "🚧";
      case CardType.carrot:
        return "🥕";
      case CardType.wheat:
        return "🌾";
      case CardType.mushroom:
        return "🍄";
    }
  }

  /// 获取卡片背景颜色
  int get color {
    switch (this) {
      case CardType.sheep:
        return 0xFFFFF3E0;
      case CardType.grass:
        return 0xFFE8F5E9;
      case CardType.tree:
        return 0xFFC8E6C9;
      case CardType.flower:
        return 0xFFFCE4EC;
      case CardType.cloud:
        return 0xFFEBF5FB;
      case CardType.sun:
        return 0xFFFFFDE7;
      case CardType.moon:
        return 0xFFE8EAF6;
      case CardType.star:
        return 0xFFF3E5F5;
      case CardType.mountain:
        return 0xFFEEEEEE;
      case CardType.river:
        return 0xFFE3F2FD;
      case CardType.house:
        return 0xFFFFEBEE;
      case CardType.fence:
        return 0xFFFFF3E0;
      case CardType.carrot:
        return 0xFFE8F5E9;
      case CardType.wheat:
        return 0xFFFFF8E1;
      case CardType.mushroom:
        return 0xFFFCE4EC;
    }
  }
}

/// 游戏难度
enum Difficulty { easy, medium, hard }

/// 卡片位置信息
class CardPosition {
  final int x;
  final int y;
  final int z; // 层级，用于绘制顺序

  CardPosition({required this.x, required this.y, required this.z});
}

/// 游戏卡片
class GameCard {
  final CardType type;
  CardPosition position;
  bool enable; // 是否可以被选择（上面没有其他卡片）
  bool hint; // 是否显示提示

  GameCard({
    required this.type,
    required this.position,
    this.enable = true,
    this.hint = false,
  });
}

/// 道具类型
enum PropType {
  removeThree, // 移除三个随机卡片
  reshuffle, // 重新排列
  hint, // 提示
}

/// 道具扩展
extension PropTypeExt on PropType {
  String get emoji {
    switch (this) {
      case PropType.removeThree:
        return "🔨";
      case PropType.reshuffle:
        return "🔄";
      case PropType.hint:
        return "💡";
    }
  }
}
