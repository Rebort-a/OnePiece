import 'package:flutter/material.dart';

import 'package:treasure/00.common/tool/notifier.dart';
import '../00.common/component/template_dialog.dart';
import '../00.common/tool/timer_counter.dart';
import 'base.dart';

class GuessManager {
  final TimerCounter _timerCounter = TimerCounter(
    const Duration(seconds: 1),
    (_) {},
  );
  int _itemCount = 6;
  late List<String> _correctItems;
  late bool _isGameOver;

  final ListNotifier<String> guessItems = ListNotifier([]);
  final ListNotifier<int> selectedIndices = ListNotifier([]);
  final ValueNotifier<String> display = ValueNotifier('');
  final ListNotifier<String> markItems = ListNotifier([]);
  final ValueNotifier<int> markItemIndex = ValueNotifier(-1);

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});

  GuessManager() {
    _initGame();
  }

  void _initGame() {
    _correctItems = (List<String>.from(
      guessItem,
    )..shuffle()).take(_itemCount).toList();
    guessItems.value = List.from(_correctItems)..shuffle();
    markItems.value = List.filled(_itemCount, "❓");
    markItemIndex.value = -1;
    _isGameOver = false;
    display.value = _displayText;
    _timerCounter.start();
  }

  void resetGame() {
    _initGame();
  }

  void _changeDifficulty(int value) {
    if (value != _itemCount) {
      _itemCount = value;
      resetGame();
    }
  }

  /// 显示难度设置对话框
  void showSelector() {
    pageNavigator.value = (context) => TemplateDialog.intSliderDialog(
      context: context,
      title: '设置难度',
      sliderData: IntSliderData(
        start: 4,
        end: guessItem.length,
        value: _itemCount,
        step: 1,
      ),
      onConfirm: _changeDifficulty,
    );
  }

  void guessSelect(int index) {
    if (_isGameOver) return;

    markItemIndex.value = -1;

    if (selectedIndices.contains(index)) {
      selectedIndices.remove(index);
    } else {
      selectedIndices.add(index);
      if (selectedIndices.length >= 2) {
        _swapItems();
      }
    }
  }

  void _swapItems() {
    final i = selectedIndices[0];
    final j = selectedIndices[1];
    final temp = guessItems[i];
    guessItems[i] = guessItems[j];
    guessItems[j] = temp;
    selectedIndices.clear();
    if (_correctCount == _itemCount) {
      _isGameOver = true;
      display.value = _displayText;
      _timerCounter.stop();
    } else {
      display.value = _displayText;
    }
  }

  String get _displayText => _isGameOver
      ? 'Time Taken: ${_timerCounter.tick} seconds'
      : 'Correct Count: $_correctCount';

  int get _correctCount {
    int count = 0;
    for (int i = 0; i < guessItems.length; i++) {
      if (guessItems[i] == _correctItems[i]) {
        count++;
      }
    }
    return count;
  }

  void markSelect(int index) {
    if (_isGameOver) return;

    if (index == -1 || markItemIndex.value == index) {
      markItemIndex.value = -1;
    } else {
      markItemIndex.value = index;
    }
  }

  void changeMark(String enmoji) {
    markItems[markItemIndex.value] = enmoji;
  }

  void leavePage() {
    pageNavigator.value = (context) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }
}
