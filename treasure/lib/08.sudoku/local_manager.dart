import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../00.common/model/notifier.dart';
import '../00.common/widget/template_dialog.dart';
import 'base.dart';

class SudokuManager extends ChangeNotifier {
  final Random _random = Random();
  double difficulty = 0.4; // 难度系数
  int boardLevel = 3;
  late int boardSize;
  final List<List<CellNotifier>> _cells = [];
  CellNotifier? _selectedCell;

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});

  // 计时相关变量
  late Stopwatch _stopwatch;
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  // 新增：游戏状态
  bool _isGameOver = false;

  SudokuManager() {
    init();
  }

  void init() {
    deselectCell();
    _initializeCells();
    _generateSudoku();
    _initTimer();
    _isGameOver = false;
  }

  // 初始化计时器
  void _initTimer() {
    if (_isGameOver) {
      _timer.cancel();
      _stopwatch.stop();
    }
    _stopwatch = Stopwatch();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_stopwatch.isRunning && !_isGameOver) {
        _elapsed = _stopwatch.elapsed;
        notifyListeners(); // 通知UI更新时间
      }
    });
    _stopwatch.start(); // 进入页面即开始计时
  }

  String get displayString {
    if (_isGameOver) {
      return '游戏结束: 用时 $_formattedTime';
    } else {
      return _formattedTime;
    }
  }

  // 获取格式化的时间字符串 (mm:ss)
  String get _formattedTime {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void changeLevel(int value) {
    if (value != boardLevel) {
      _isGameOver = true;
      boardLevel = value;
      init();
      notifyListeners();
    }
  }

  void changeDifficulty(double value) {
    if (value != difficulty) {
      _isGameOver = true;
      difficulty = value;
      init();
      notifyListeners();
    }
  }

  void showSelector() {
    pageNavigator.value = (context) {
      TemplateDialog.sliderDialog(
        context: context,
        title: '设置难度',
        sliderData: SliderData(
          start: 0.2,
          end: 0.8,
          value: difficulty,
          step: 0.1,
        ),
        onConfirm: changeDifficulty,
      );
    };
  }

  List<List<CellNotifier>> get cells => _cells;
  CellNotifier? get selectedCell => _selectedCell;

  void _initializeCells() {
    boardSize = boardLevel * boardLevel;
    _cells.clear();
    for (int i = 0; i < boardSize; i++) {
      final List<CellNotifier> row = [];
      for (int j = 0; j < boardSize; j++) {
        row.add(
          CellNotifier(SudokuCell(row: i, col: j, type: CellType.editable)),
        );
      }
      _cells.add(row);
    }
  }

  void selectCell(CellNotifier cell) {
    _selectedCell = cell;
    notifyListeners();
  }

  void deselectCell() {
    if (_selectedCell != null) {
      _selectedCell = null;
      notifyListeners();
    }
  }

  void addDigit(int digit) {
    if (_selectedCell != null) {
      _selectedCell!.addDigit(digit);
    }
  }

  void removeDigit(int digit) {
    if (_selectedCell != null) {
      _selectedCell!.removeDigit(digit);
    }
  }

  void clearDigits() {
    if (_selectedCell != null) {
      _selectedCell!.clearDigits();
    }
  }

  void lock() {
    if (_selectedCell != null) {
      _selectedCell!.lock();
      if (isGameComplete()) {
        _onGameComplete(); // 游戏完成时调用处理函数
      }
    }
  }

  void unlock() {
    if (_selectedCell != null) {
      _selectedCell!.unlock();
    }
  }

  /// 新增：游戏完成处理函数
  void _onGameComplete() {
    _isGameOver = true;
    _stopwatch.stop(); // 停止计时
    notifyListeners(); // 通知UI游戏已结束
  }

  /// 检查游戏是否完成（所有单元格已填写且有效）
  bool isGameComplete() {
    // 检查是否所有单元格都已锁定或固定
    for (final row in _cells) {
      for (final cell in row) {
        if (cell.value.type == CellType.editable) {
          return false;
        }
      }
    }
    return _isValidSolution();
  }

  /// 验证当前解是否有效
  bool _isValidSolution() {
    // 检查每行
    for (int i = 0; i < boardSize; i++) {
      final values = <int>[];
      for (int j = 0; j < boardSize; j++) {
        final value = _cells[i][j].value.fixedDigit;
        if (value == 0 || values.contains(value)) return false;
        values.add(value);
      }
    }

    // 检查每列
    for (int j = 0; j < boardSize; j++) {
      final values = <int>[];
      for (int i = 0; i < boardSize; i++) {
        final value = _cells[i][j].value.fixedDigit;
        if (value == 0 || values.contains(value)) return false;
        values.add(value);
      }
    }

    // 检查每个宫格
    for (int boxRow = 0; boxRow < boardLevel; boxRow++) {
      for (int boxCol = 0; boxCol < boardLevel; boxCol++) {
        final values = <int>[];
        for (int i = 0; i < boardLevel; i++) {
          for (int j = 0; j < boardLevel; j++) {
            final row = boxRow * boardLevel + i;
            final col = boxCol * boardLevel + j;
            final value = _cells[row][col].value.fixedDigit;
            if (value == 0 || values.contains(value)) return false;
            values.add(value);
          }
        }
      }
    }

    return true;
  }

  void reset() {
    init();
    notifyListeners();
  }

  /// 生成数独谜题
  void _generateSudoku() {
    // 1. 生成完整解
    _fillDiagonalBoxes();
    _fillRemaining(0, boardLevel);

    // 2. 移除数字生成谜题（根据难度调整移除数量）
    final int cellsToRemove = (boardSize * boardSize * difficulty)
        .floor(); // 移除40%的数字
    _removeNumbers(cellsToRemove);
  }

  /// 填充对角线上的宫格（确保初始解的生成）
  void _fillDiagonalBoxes() {
    for (int i = 0; i < boardSize; i += boardLevel) {
      _fillBox(i, i);
    }
  }

  /// 填充单个宫格
  void _fillBox(int startRow, int startCol) {
    for (int i = 0; i < boardLevel; i++) {
      for (int j = 0; j < boardLevel; j++) {
        int num;
        do {
          num = _randomNumber();
        } while (!_isSafeInBox(startRow, startCol, num));

        _cells[startRow + i][startCol + j] = CellNotifier(
          SudokuCell(
            row: startRow + i,
            col: startCol + j,
            type: CellType.fixed,
            fixedDigit: num,
          ),
        );
      }
    }
  }

  /// 生成1-boardSize之间的随机数
  int _randomNumber() => _random.nextInt(boardSize) + 1;

  /// 检查数字在宫格中是否安全
  bool _isSafeInBox(int boxStartRow, int boxStartCol, int num) {
    for (int i = 0; i < boardLevel; i++) {
      for (int j = 0; j < boardLevel; j++) {
        if (_cells[boxStartRow + i][boxStartCol + j].value.fixedDigit == num) {
          return false;
        }
      }
    }
    return true;
  }

  /// 检查数字在当前位置是否安全（行、列、宫格都不重复）
  bool _isSafe(int row, int col, int num) {
    return _isSafeInRow(row, num) &&
        _isSafeInCol(col, num) &&
        _isSafeInBox(row - row % boardLevel, col - col % boardLevel, num);
  }

  /// 检查数字在当前行是否安全
  bool _isSafeInRow(int row, int num) {
    for (int i = 0; i < boardSize; i++) {
      if (_cells[row][i].value.fixedDigit == num) {
        return false;
      }
    }
    return true;
  }

  /// 检查数字在当前列是否安全
  bool _isSafeInCol(int col, int num) {
    for (int i = 0; i < boardSize; i++) {
      if (_cells[i][col].value.fixedDigit == num) {
        return false;
      }
    }
    return true;
  }

  /// 填充剩余单元格
  bool _fillRemaining(int i, int j) {
    if (j >= boardSize && i < boardSize - 1) {
      i++;
      j = 0;
    }
    if (i >= boardSize && j >= boardSize) {
      return true;
    }
    if (i < boardLevel) {
      if (j < boardLevel) {
        j = boardLevel;
      }
    } else if (i < boardSize - boardLevel) {
      if (j == (i ~/ boardLevel) * boardLevel) {
        j += boardLevel;
      }
    } else {
      if (j == boardSize - boardLevel) {
        i++;
        j = 0;
        if (i >= boardSize) {
          return true;
        }
      }
    }

    for (int num = 1; num <= boardSize; num++) {
      if (_isSafe(i, j, num)) {
        _cells[i][j] = CellNotifier(
          SudokuCell(row: i, col: j, type: CellType.fixed, fixedDigit: num),
        );
        if (_fillRemaining(i, j + 1)) {
          return true;
        }
        _cells[i][j] = CellNotifier(
          SudokuCell(row: i, col: j, type: CellType.editable),
        );
      }
    }
    return false;
  }

  /// 移除数字生成谜题
  void _removeNumbers(int count) {
    int cellsRemoved = 0;
    while (cellsRemoved < count) {
      final i = _random.nextInt(boardSize);
      final j = _random.nextInt(boardSize);

      if (_cells[i][j].value.type == CellType.fixed) {
        // 临时保存当前值用于检查唯一性
        final tempValue = _cells[i][j].value.fixedDigit;
        _cells[i][j] = CellNotifier(
          SudokuCell(row: i, col: j, type: CellType.editable),
        );

        // 简单检查解的唯一性
        if (_hasUniqueSolution()) {
          cellsRemoved++;
        } else {
          // 如果解不唯一，恢复原值
          _cells[i][j] = CellNotifier(
            SudokuCell(
              row: i,
              col: j,
              type: CellType.fixed,
              fixedDigit: tempValue,
            ),
          );
        }
      }
    }
  }

  /// 检查解的唯一性
  bool _hasUniqueSolution() {
    // 实际应用中需要实现完整的解唯一性检查算法
    // 这里简化为假设移除后仍有唯一解
    return true;
  }

  // 释放资源
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
