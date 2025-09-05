import 'dart:math';
import 'package:flutter/material.dart';
import '../00.common/component/template_dialog.dart';
import '../00.common/tool/notifier.dart';
import '../00.common/tool/timer_counter.dart';
import 'base.dart';

/// 卡片尺寸常量
const double _cardW = 50, _cardH = 50; // 单张卡片宽高
const double mainRegionWidth = 600, mainRegionHeight = 600; // 游戏区域尺寸
const int _safeMargin = 50; // 离边距

/// 3TILES游戏管理器
class ThreeTilesManager {
  final Random _random = Random();
  late final TimerCounter _timer;

  Difficulty _difficulty = Difficulty.medium;
  bool _isGameOver = false;

  final ListNotifier<GameCard> cards = ListNotifier([]);
  final ListNotifier<GameCard> selectedCards = ListNotifier([]);
  final ListNotifier<PropType> props = ListNotifier([]);
  final ValueNotifier<int> elapsed = ValueNotifier(0);

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});

  ThreeTilesManager() {
    _initTimer();
    _initGame();
  }

  void _initTimer() {
    _timer = TimerCounter(const Duration(seconds: 1), (int tick) {
      elapsed.value = tick;
    });
  }

  // 初始化游戏
  void _initGame() {
    _isGameOver = false;

    // 初始化道具
    props.add(PropType.removeThree);
    props.add(PropType.reshuffle);
    props.add(PropType.hint);

    // 根据难度创建不同数量的卡片
    _generateCards((_difficulty.index + 1) * 30);

    // 开始计时
    _timer.start();
  }

  // 生成卡片
  void _generateCards(int count) {
    final positions = _generateCardPositions(count);
    final cardTypes = CardType.values;
    final typeQuota = (count / 3).ceil(); // 每种最多出现多少次
    final typeCounter = <CardType, int>{};
    for (final t in cardTypes) {
      typeCounter[t] = 0;
    }

    final typePool = cardTypes.toList()..shuffle(_random);

    int posIndex = 0;
    while (posIndex < count) {
      // 轮询池子，避免某种类型无限追加
      for (final t in typePool) {
        if (posIndex >= count) break;
        if (typeCounter[t]! >= typeQuota) continue;
        // 一次性追加 3 张，保证可消除
        for (int i = 0; i < 3; i++) {
          cards.add(GameCard(type: t, position: positions[posIndex]));
          posIndex++;
          if (posIndex >= count) break;
          typeCounter[t] = typeCounter[t]! + 1;
        }
      }
    }

    cards.value = List<GameCard>.from(cards.value)
      ..sort((a, b) => a.position.z.compareTo(b.position.z));

    _updateCardVisibility();
  }

  // 生成卡片位置
  List<CardPosition> _generateCardPositions(int count) {
    final layerCount = (count / 15).ceil() + 1; // 仍按 15 张/层估算
    final positions = <CardPosition>[];

    for (int z = 0; z < layerCount; z++) {
      // 每层向内收缩系数，0 层最外，顶层最内
      final shrink = z * 0.08; // 可调，越大越往中间挤
      final xMin = _safeMargin + (mainRegionWidth * shrink / 2);
      final xMax =
          mainRegionWidth - _safeMargin - (mainRegionWidth * shrink / 2);
      final yMin = _safeMargin + (mainRegionHeight * shrink / 2);
      final yMax =
          mainRegionHeight - _safeMargin - (mainRegionHeight * shrink / 2);

      // 本层需要放几张
      final quota = (count / layerCount).ceil();
      for (int i = 0; i < quota && positions.length < count; i++) {
        final x = xMin + _random.nextDouble() * (xMax - xMin);
        final y = yMin + _random.nextDouble() * (yMax - yMin);
        positions.add(CardPosition(x: x.round(), y: y.round(), z: z));
      }
    }
    return positions;
  }

  // 更新卡片可见性（上层卡片覆盖下层）
  void _updateCardVisibility() {
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final cardRect = Rect.fromLTWH(
        card.position.x.toDouble(),
        card.position.y.toDouble(),
        _cardW,
        _cardH,
      );

      bool isCovered = false;
      for (int j = i + 1; j < cards.length; j++) {
        final upper = cards[j];
        final upperRect = Rect.fromLTWH(
          upper.position.x.toDouble(),
          upper.position.y.toDouble(),
          _cardW,
          _cardH,
        );
        if (upperRect.overlaps(cardRect)) {
          isCovered = true;
          break;
        }
      }
      card.enable = !isCovered;
    }
    cards.update();
  }

  // 选择卡片
  void selectCard(GameCard card) {
    if (_isGameOver || !card.enable) return;

    // 选中卡片
    selectedCards.add(card);
    cards.remove(card);
    _updateCardVisibility();

    // 检查是否有3个相同的卡片
    _checkForMatches();

    // 检查是否已选满7个
    if (selectedCards.value.length >= 7) {
      // 游戏结束
      _handleGameOver(false);
    }
  }

  // 检查是否有3个相同的卡片
  void _checkForMatches() {
    if (selectedCards.value.length < 3) return;

    // 按类型分组
    final Map<CardType, List<GameCard>> groups = {};
    for (var card in selectedCards.value) {
      if (!groups.containsKey(card.type)) {
        groups[card.type] = [];
      }
      groups[card.type]!.add(card);
    }

    // 查找有3个相同的组
    for (var group in groups.values) {
      if (group.length >= 3) {
        // 移除这3个卡片
        for (var card in group.take(3)) {
          selectedCards.remove(card);
        }

        // 更新可见性
        _updateCardVisibility();

        // 检查游戏是否胜利
        _checkVictory();
        return;
      }
    }
  }

  // 使用道具
  void useProp(PropType prop) {
    if (_isGameOver) return;

    switch (prop) {
      case PropType.removeThree:
        _removeThreeRandomCards();
        break;
      case PropType.reshuffle:
        _reshuffleCards();
        break;
      case PropType.hint:
        _showHint();
        break;
    }

    // 移除已使用的道具
    props.remove(prop);
  }

  // 移除三个随机卡片
  void _removeThreeRandomCards() {
    final enableCards = cards.value.toList();
    if (enableCards.length < 3) return;

    enableCards.shuffle();
    for (var card in enableCards.take(3)) {
      cards.remove(card);
    }

    _updateCardVisibility();
    _checkVictory();
  }

  // 重新排列卡片
  void _reshuffleCards() {
    final positions = _generateCardPositions(cards.length);

    for (var card in cards.value) {
      card.position = positions.removeAt(0);
    }

    _updateCardVisibility();
  }

  // 显示提示
  void _showHint() {
    final visible = cards.value.where((c) => c.enable).toList();
    final Map<CardType, List<GameCard>> groups = {};
    for (var c in visible) {
      groups.putIfAbsent(c.type, () => []).add(c);
    }
    // 找到第一种≥3张的组
    final target = groups.values.cast<List<GameCard>?>().firstWhere(
      (g) => g!.length >= 3,
      orElse: () => null,
    );
    if (target == null) return; // 无提示

    // 高亮 3 张
    for (var c in target.take(3)) {
      c.hint = true;
    }
    cards.update();
  }

  // 检查是否胜利
  void _checkVictory() {
    if (cards.isEmpty) {
      _handleGameOver(true);
    }
  }

  // 游戏结束
  void _handleGameOver(bool victory) {
    _showGameOverDialog(victory);
  }

  // 重新开始游戏
  void restartGame() {
    _clearUp();
    _initGame();
  }

  // 游戏结束对话框
  void _showGameOverDialog(bool victory) {
    pageNavigator.value = (BuildContext context) {
      TemplateDialog.confirmDialog(
        context: context,
        title: victory ? "恭喜通关！" : "游戏结束",
        content: "用时: ${elapsed.value}",
        before: () {
          return true;
        },
        onTap: () {},
        after: () {
          _clearUp();
        },
      );
    };
  }

  // 难度选择对话框
  void showDifficultyDialog() {
    pageNavigator.value = (BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("选择难度"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyTile(context, Difficulty.easy, "简单"),
            _buildDifficultyTile(context, Difficulty.medium, "中等"),
            _buildDifficultyTile(context, Difficulty.hard, "困难"),
          ],
        ),
      ),
    );
  }

  // 提取重复的Radio ListTile构建逻辑
  ListTile _buildDifficultyTile(
    BuildContext context,
    Difficulty difficulty,
    String label,
  ) {
    return ListTile(
      title: Text(label),
      leading: Radio<Difficulty>(
        value: difficulty,
        groupValue: _difficulty,
        onChanged: (value) {
          if (value != null) {
            Navigator.pop(context);
            _changeDifficulty(value);
          }
        },
      ),
    );
  }

  // 改变难度
  void _changeDifficulty(Difficulty difficulty) {
    _clearUp();
    _difficulty = difficulty;
    _initGame();
  }

  void leavePage() {
    _clearUp();
    pageNavigator.value = (context) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }

  void _clearUp() {
    _timer.stop();
    cards.clear();
    props.clear();
    selectedCards.clear();
    _isGameOver = true;
    elapsed.value = 0;
  }
}
