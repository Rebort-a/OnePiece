import 'dart:math';
import 'package:flutter/material.dart';
import '../00.common/component/template_dialog.dart';
import '../00.common/tool/notifier.dart';
import '../00.common/tool/timer_counter.dart';
import 'base.dart';

/// 虚拟棋牌大小
const double boardVirtualWidth = 600;
const double boardVirtualHeight = 800;

/// 虚拟卡片大小
const double cardVirtualSize = 80;

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
    _timer = TimerCounter(const Duration(seconds: 1), (tick) {
      elapsed.value = tick;
    });
  }

  void _initGame() {
    props
      ..clear()
      ..addAll([PropType.removeThree, PropType.reshuffle, PropType.hint]);

    _generateCards((_difficulty.index + 1) * 30);
    _timer.start();

    _isGameOver = false;
  }

  void _generateCards(int count) {
    final positions = _generateCardPositions(count);
    final cardTypes = CardType.values;
    final typeQuota = (count / 3).ceil();
    final typeCounter = <CardType, int>{};
    for (final t in cardTypes) {
      typeCounter[t] = 0;
    }

    final typePool = cardTypes.toList()..shuffle(_random);

    int posIndex = 0;
    while (posIndex < count) {
      for (final t in typePool) {
        if (posIndex >= count) break;
        if (typeCounter[t]! >= typeQuota) continue;
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

  List<CardPosition> _generateCardPositions(int count) {
    final layerCount = (count / 15).ceil() + 1;
    final positions = <CardPosition>[];

    for (int z = 0; z < layerCount; z++) {
      final shrink = z * 0.08;
      final xMin = (boardVirtualWidth * shrink / 2);
      final xMax =
          boardVirtualWidth -
          cardVirtualSize -
          (boardVirtualWidth * shrink / 2);
      final yMin = (boardVirtualHeight * shrink / 2);
      final yMax =
          boardVirtualHeight -
          cardVirtualSize -
          (boardVirtualHeight * shrink / 2);

      final quota = (count / layerCount).ceil();
      for (int i = 0; i < quota && positions.length < count; i++) {
        final x = xMin + _random.nextDouble() * (xMax - xMin);
        final y = yMin + _random.nextDouble() * (yMax - yMin);
        positions.add(CardPosition(x: x.round(), y: y.round(), z: z));
      }
    }
    return positions;
  }

  void _updateCardVisibility() {
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];
      final cardRect = Rect.fromLTWH(
        card.position.x.toDouble(),
        card.position.y.toDouble(),
        cardVirtualSize,
        cardVirtualSize,
      );

      bool isCovered = false;
      for (int j = i + 1; j < cards.length; j++) {
        final upper = cards[j];
        final upperRect = Rect.fromLTWH(
          upper.position.x.toDouble(),
          upper.position.y.toDouble(),
          cardVirtualSize,
          cardVirtualSize,
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

  void selectCard(GameCard card) {
    if (_isGameOver || !card.enable) return;
    selectedCards.add(card);
    cards.remove(card);
    _updateCardVisibility();
    _checkForMatches();
    if (selectedCards.value.length >= 7) _handleGameOver(false);
  }

  void _checkForMatches() {
    if (selectedCards.value.length < 3) return;
    final groups = <CardType, List<GameCard>>{};
    for (final c in selectedCards.value) {
      groups.putIfAbsent(c.type, () => []).add(c);
    }
    for (final group in groups.values) {
      if (group.length >= 3) {
        for (final c in group.take(3).toList()) {
          selectedCards.remove(c);
        }
        _updateCardVisibility();
        _checkVictory();
        return;
      }
    }
  }

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
    props.remove(prop);
  }

  void _removeThreeRandomCards() {
    final enableCards = cards.value.toList();
    if (enableCards.length < 3) return;
    enableCards.shuffle(_random);
    for (final c in enableCards.take(3)) {
      cards.remove(c);
    }
    _updateCardVisibility();
    _checkVictory();
  }

  void _reshuffleCards() {
    final newPositions = _generateCardPositions(cards.length);
    for (int i = 0; i < cards.length; i++) {
      cards[i].position = newPositions[i];
    }
    cards.update();
    _updateCardVisibility();
  }

  void _showHint() {
    final visible = cards.value.where((c) => c.enable).toList();
    final groups = <CardType, List<GameCard>>{};
    for (final c in visible) {
      groups.putIfAbsent(c.type, () => []).add(c);
    }
    final target = groups.values.cast<List<GameCard>?>().firstWhere(
      (g) => g!.length >= 3,
      orElse: () => null,
    );
    if (target == null) return;
    for (final c in target.take(3)) {
      c.hint = true;
    }
    cards.update();
  }

  void _checkVictory() {
    if (cards.isEmpty) _handleGameOver(true);
  }

  void _handleGameOver(bool victory) {
    _showGameOverDialog(victory);
  }

  void restartGame() {
    _clearUp();
    _initGame();
  }

  void _showGameOverDialog(bool victory) {
    pageNavigator.value = (context) {
      TemplateDialog.confirmDialog(
        context: context,
        title: victory ? '恭喜通关！' : '游戏结束',
        content: '用时: ${elapsed.value} 秒',
        before: () => true,
        onTap: () {},
        after: _clearUp,
      );
    };
  }

  void showDifficultyDialog() {
    pageNavigator.value = (context) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('选择难度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Difficulty.values
              .map((e) => _buildDifficultyTile(context, e))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildDifficultyTile(BuildContext context, Difficulty difficulty) {
    return RadioMenuButton<Difficulty>(
      value: difficulty,
      groupValue: _difficulty,
      onChanged: (Difficulty? value) {
        if (value == null) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _changeDifficulty(value);
      },
      child: Text(difficulty.label),
    );
  }

  void _changeDifficulty(Difficulty d) {
    _clearUp();
    _difficulty = d;
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

extension on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return "简单";
      case Difficulty.medium:
        return "中等";
      case Difficulty.hard:
        return "困难";
    }
  }
}
