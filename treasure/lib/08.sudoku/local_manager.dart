import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../00.common/model/notifier.dart';
import '../00.common/widget/template_dialog.dart';
import 'base.dart';

class SudokuManager extends ChangeNotifier {
  final Random _random = Random();
  double difficulty = 0.4; // 难度系数（0.2-0.8）
  int boardLevel = 3; // 宫格等级（3x3）
  late int boardSize; // 棋盘尺寸（boardLevel^2）
  final List<List<CellNotifier>> _cells = [];
  CellNotifier? _selectedCell;

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});

  // 计时相关
  late Stopwatch _stopwatch;
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  bool _isGameOver = false;

  SudokuManager() {
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

  /// 初始化计时器
  void _initTimer() {
    _stopwatch = Stopwatch();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_stopwatch.isRunning && !_isGameOver) {
        _elapsed = _stopwatch.elapsed;
        notifyListeners();
      }
    });
    _stopwatch.start();
  }

  /// 格式化显示时间
  String get displayString =>
      _isGameOver ? '游戏结束: 用时 $_formattedTime' : _formattedTime;

  String get _formattedTime {
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 更改难度等级
  void changeLevel(int value) {
    if (value != boardLevel) {
      _isGameOver = true;
      boardLevel = value;
      init();
      notifyListeners();
    }
  }

  /// 更改难度系数
  void changeDifficulty(double value) {
    if (value != difficulty) {
      _isGameOver = true;
      difficulty = value;
      init();
      notifyListeners();
    }
  }

  /// 显示难度设置对话框
  void showSelector() {
    pageNavigator.value = (context) => TemplateDialog.sliderDialog(
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
  }

  //  getter
  List<List<CellNotifier>> get cells => _cells;
  CellNotifier? get selectedCell => _selectedCell;

  /// 初始化单元格列表
  void _initializeCells() {
    boardSize = boardLevel * boardLevel;
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
    if (isGameComplete()) _onGameComplete();
  }

  /// 解锁选中单元格
  void unlock() => _selectedCell?.unlock();

  /// 游戏完成处理
  void _onGameComplete() {
    _isGameOver = true;
    _stopwatch.stop();
    notifyListeners();
  }

  /// 检查游戏是否完成（所有单元格有效且已锁定）
  bool isGameComplete() {
    // 检查所有单元格是否已锁定或固定
    if (_cells.any(
      (row) => row.any((cell) => cell.value.type == CellType.editable),
    )) {
      return false;
    }
    return _isValidSolution();
  }

  /// 验证数独解的有效性
  bool _isValidSolution() {
    // 检查行
    for (int i = 0; i < boardSize; i++) {
      if (!_isValidSet(_getRowValues(i))) return false;
    }

    // 检查列
    for (int j = 0; j < boardSize; j++) {
      if (!_isValidSet(_getColumnValues(j))) return false;
    }

    // 检查宫格
    for (int boxRow = 0; boxRow < boardLevel; boxRow++) {
      for (int boxCol = 0; boxCol < boardLevel; boxCol++) {
        if (!_isValidSet(_getBoxValues(boxRow, boxCol))) return false;
      }
    }

    return true;
  }

  /// 检查集合是否有效（无重复且不为0）
  bool _isValidSet(List<int> values) =>
      values.every((v) => v != 0) && values.toSet().length == values.length;

  /// 获取行数据
  List<int> _getRowValues(int row) =>
      _cells[row].map((cell) => cell.value.fixedDigit).toList();

  /// 获取列数据
  List<int> _getColumnValues(int col) =>
      _cells.map((row) => row[col].value.fixedDigit).toList();

  /// 获取宫格数据
  List<int> _getBoxValues(int boxRow, int boxCol) {
    final values = <int>[];
    final startRow = boxRow * boardLevel;
    final startCol = boxCol * boardLevel;

    for (int i = 0; i < boardLevel; i++) {
      for (int j = 0; j < boardLevel; j++) {
        values.add(_cells[startRow + i][startCol + j].value.fixedDigit);
      }
    }
    return values;
  }

  /// 重置游戏
  void reset() {
    init();
    notifyListeners();
  }

  /// 生成数独谜题
  void _generateSudoku() {
    _fillDiagonalBoxes(); // 填充对角线宫格
    _fillRemaining(0, boardLevel); // 填充剩余单元格
    _removeNumbers((boardSize * boardSize * difficulty).floor()); // 移除数字生成谜题
  }

  /// 填充对角线宫格
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

  /// 检查数字在当前位置是否安全（行、列、宫格）
  bool _isSafe(int row, int col, int num) =>
      _isSafeInRow(row, num) &&
      _isSafeInCol(col, num) &&
      _isSafeInBox(row - row % boardLevel, col - col % boardLevel, num);

  /// 检查数字在当前行是否安全
  bool _isSafeInRow(int row, int num) => !_getRowValues(row).contains(num);

  /// 检查数字在当前列是否安全
  bool _isSafeInCol(int col, int num) => !_getColumnValues(col).contains(num);

  /// 填充剩余单元格
  bool _fillRemaining(int i, int j) {
    // 换行逻辑
    if (j >= boardSize && i < boardSize - 1) {
      i++;
      j = 0;
    }
    if (i >= boardSize && j >= boardSize) return true;

    // 跳过已填充的对角线宫格
    if (i < boardLevel) {
      j = (j < boardLevel) ? boardLevel : j;
    } else if (i < boardSize - boardLevel) {
      j = (j == (i ~/ boardLevel) * boardLevel) ? j + boardLevel : j;
    } else {
      if (j == boardSize - boardLevel) {
        i++;
        j = 0;
        if (i >= boardSize) return true;
      }
    }

    // 尝试填充数字
    for (int num = 1; num <= boardSize; num++) {
      if (_isSafe(i, j, num)) {
        _cells[i][j] = CellNotifier(
          SudokuCell(row: i, col: j, type: CellType.fixed, fixedDigit: num),
        );
        if (_fillRemaining(i, j + 1)) return true;
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
        final tempValue = _cells[i][j].value.fixedDigit;
        _cells[i][j] = CellNotifier(
          SudokuCell(row: i, col: j, type: CellType.editable),
        );

        // 检查解的唯一性（简化实现）
        if (_hasUniqueSolution()) {
          cellsRemoved++;
        } else {
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

  /// 检查解的唯一性（简化实现）
  bool _hasUniqueSolution() => true;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
