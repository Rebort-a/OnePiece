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

  late bool _isGameOver;
  final ListNotifier<String> correctItems = ListNotifier([]);
  final ListNotifier<String> guessItems = ListNotifier([]);
  final ListNotifier<String> markItems = ListNotifier([]);
  final ValueNotifier<int> selectedItem = ValueNotifier(-1);
  final ValueNotifier<String> display = ValueNotifier('');

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});

  GuessManager() {
    _initGame();
  }

  int get itemCount => _itemCount;

  void _initGame() {
    correctItems.value = (List<String>.from(
      guessItem,
    )..shuffle()).take(_itemCount).toList();
    guessItems.value = List.from(correctItems.value)..shuffle();
    markItems.value = List.filled(_itemCount, MarkType.unknown.emoji);
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

    if (selectedItem.value == index) {
      selectedItem.value = -1;
    } else {
      _swapItems(selectedItem.value, index);
    }
  }

  void _swapItems(int i, int j) {
    String temp = guessItems[i];
    guessItems[i] = guessItems[j];
    guessItems[j] = temp;
    selectedItem.value = -1;
    if (_correctCount == _itemCount) {
      _handleGameOver();
    } else {
      display.value = _displayText;
    }
  }

  void _handleGameOver() {
    _isGameOver = true;
    display.value = _displayText;
    markItems.value = List.from(guessItems.value);
    _timerCounter.stop();
  }

  String get _displayText => _isGameOver
      ? 'Time Taken: ${_timerCounter.tick} seconds'
      : 'Correct Count: $_correctCount';

  int get _correctCount {
    int count = 0;
    for (int i = 0; i < guessItems.length; i++) {
      if (guessItems[i] == correctItems[i]) {
        count++;
      }
    }
    return count;
  }

  void markSelect(int index) {
    if (_isGameOver) return;

    selectedItem.value = -1;

    markItems[index] = MarkTypeExt.toggle(markItems[index]);
  }

  void leavePage() {
    pageNavigator.value = (context) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }
}
