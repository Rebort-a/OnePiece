import 'dart:async';

import 'package:flutter/material.dart';

import '../00.common/model/notifier.dart';
import '../00.common/widget/template_dialog.dart';
import 'algorithm.dart';
import 'base.dart';

class SudokuManager extends ChangeNotifier {
  int boardLevel = 3; // 固定为9x9数独（3x3宫格）
  late int boardSize; // 棋盘尺寸（9x9）
  late int difficulty; // 移除的数字数量（9-64）
  final List<List<CellNotifier>> _cells = [];
  CellNotifier? _selectedCell;

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});

  bool _isGameOver = false;
  late List<List<int>> _solution; // 存储数独的解

  // 计时相关
  late Stopwatch _stopwatch;
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  SudokuManager() {
    boardSize = boardLevel * boardLevel;
    difficulty = boardSize * boardLevel;
    init();
  }

  /// 初始化游戏
  void init() {
    deselectCell();
    _initializeCells();
    _generateSudoku();
    _initTimer();
    _isGameOver = false;
  }

  //  getter
  List<List<CellNotifier>> get cells => _cells;
  CellNotifier? get selectedCell => _selectedCell;

  /// 初始化单元格列表
  void _initializeCells() {
    _cells
      ..clear()
      ..addAll(
        List.generate(
          boardSize,
          (i) => List.generate(
            boardSize,
            (j) => CellNotifier(
              SudokuCell(row: i, col: j, type: CellType.editable),
            ),
          ),
        ),
      );
  }

  /// 生成数独谜题（保证唯一解）
  void _generateSudoku() {
    // 使用SudokuGenerator生成数独
    final generator = SudokuGenerator(
      level: boardLevel,
      difficulty: difficulty,
    );
    final puzzle = generator.generate();
    _solution = generator.getSolution();

    // 更新难度为实际生成的难度（可能已降低）
    difficulty = generator.difficulty;

    // 将生成的数独填充到单元格
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        final value = puzzle[i][j];
        if (value != 0) {
          // 预填的数字设为固定类型
          _cells[i][j].value = SudokuCell(
            row: i,
            col: j,
            type: CellType.fixed,
            fixedDigit: value,
          );
        } else {
          // 空白格子设为可编辑
          _cells[i][j].value = SudokuCell(
            row: i,
            col: j,
            type: CellType.editable,
          );
        }
      }
    }
  }

  /// 初始化计时器
  void _initTimer() {
    // 初始化时不会进入，重置游戏时才会进入
    if (_isGameOver) {
      _timer.cancel();
      _stopwatch.stop();
    }

    _stopwatch = Stopwatch();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopwatch.isRunning && !_isGameOver) {
        _elapsed = _stopwatch.elapsed;
      }
    });
    _stopwatch.start();
  }

  String get displayString =>
      _isGameOver ? '游戏结束 难度$difficulty 用时 $_formattedTime' : '';

  /// 格式化显示时间
  String get _formattedTime {
    final hours = _elapsed.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// 显示难度设置对话框
  void showSelector() {
    pageNavigator.value = (context) => TemplateDialog.intSliderDialog(
      context: context,
      title: '设置难度',
      sliderData: IntSliderData(
        start: boardSize,
        end: boardSize * (boardSize - 2) + 1,
        value: difficulty,
        step: 1, // 步长为1，支持精细调整
      ),
      onConfirm: _changeDifficulty,
    );
  }

  /// 更改难度系数
  void _changeDifficulty(int value) {
    if (value != difficulty) {
      _isGameOver = true;
      difficulty = value;
      init();
      notifyListeners();
    }
  }

  void changeLevel(int value) {
    if (value != boardLevel) {
      _isGameOver = true;
      boardLevel = value;
      boardSize = boardLevel * boardLevel;
      init();
      notifyListeners();
    }
  }

  /// 选择单元格
  void selectCell(CellNotifier cell) {
    _selectedCell = cell;
    notifyListeners();
  }

  /// 取消选择
  void deselectCell() {
    if (_selectedCell != null) {
      _selectedCell = null;
      notifyListeners();
    }
  }

  /// 向选中单元格添加数字
  void addDigit(int digit) => _selectedCell?.addDigit(digit);

  /// 从选中单元格移除数字
  void removeDigit(int digit) => _selectedCell?.removeDigit(digit);

  /// 清空选中单元格数字
  void clearDigits() => _selectedCell?.clearDigits();

  /// 锁定选中单元格
  void lock() {
    _selectedCell?.lock();
    if (_isGameComplete()) _onGameComplete();
  }

  /// 解锁选中单元格
  void unlock() => _selectedCell?.unlock();

  /// 检查游戏是否完成（所有单元格有效且已锁定）
  bool _isGameComplete() {
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        final cell = _cells[i][j].value;
        // 检查所有单元格是否已锁定且值正确
        if (cell.type == CellType.editable ||
            cell.fixedDigit != _solution[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  /// 检查单元格的值是否正确
  bool isCellCorrect(CellNotifier cell) {
    final solutionValue = _solution[cell.value.row][cell.value.col];
    return cell.value.fixedDigit == solutionValue;
  }

  /// 游戏完成处理
  void _onGameComplete() {
    _isGameOver = true;
    _stopwatch.stop();
    notifyListeners();
  }

  /// 重置游戏
  void reset() {
    _isGameOver = true;
    init();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
