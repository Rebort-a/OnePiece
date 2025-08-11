import 'dart:math';

class SudokuGenerator {
  final int level;
  int difficulty; // 空白格子数
  late int _size;
  late int _boxSize;
  late List<List<int>> _sudoku;
  late List<List<int>> _solution;

  SudokuGenerator({required this.level, required this.difficulty}) {
    _size = level * level;
    _boxSize = level;
    _sudoku = List.generate(_size, (i) => List.filled(_size, 0));
    _solution = List.generate(_size, (i) => List.filled(_size, 0));
  }

  List<List<int>> generate() {
    // 首先生成一个完整的数独解
    _generateCompleteSudoku();

    // 复制完整解作为答案
    _copySolution();

    // 根据难度移除数字（difficulty是需要填入的数量），确保唯一解
    _removeNumbers();

    return _sudoku;
  }

  List<List<int>> getSolution() {
    return _solution;
  }

  void _generateCompleteSudoku() {
    _fillDiagonalBoxes();
    _fillRemaining(0, _boxSize);
  }

  void _fillDiagonalBoxes() {
    for (int i = 0; i < _size; i += _boxSize) {
      _fillBox(i, i);
    }
  }

  void _fillBox(int row, int col) {
    int num;
    final random = Random();

    for (int i = 0; i < _boxSize; i++) {
      for (int j = 0; j < _boxSize; j++) {
        do {
          num = random.nextInt(_size) + 1;
        } while (!_isNumberUsedInBox(row, col, num));

        _sudoku[row + i][col + j] = num;
      }
    }
  }

  bool _isNumberUsedInBox(int boxRow, int boxCol, int num) {
    for (int i = 0; i < _boxSize; i++) {
      for (int j = 0; j < _boxSize; j++) {
        if (_sudoku[boxRow + i][boxCol + j] == num) {
          return false;
        }
      }
    }
    return true;
  }

  bool _fillRemaining(int i, int j) {
    if (j >= _size && i < _size - 1) {
      i += 1;
      j = 0;
    }
    if (i >= _size && j >= _size) {
      return true;
    }
    if (i < _boxSize) {
      if (j < _boxSize) {
        j = _boxSize;
      }
    } else if (i < _size - _boxSize) {
      if (j == (i ~/ _boxSize) * _boxSize) {
        j += _boxSize;
      }
    } else {
      if (j == _size - _boxSize) {
        i += 1;
        j = 0;
        if (i >= _size) {
          return true;
        }
      }
    }

    for (int num = 1; num <= _size; num++) {
      if (_isValid(i, j, num)) {
        _sudoku[i][j] = num;
        if (_fillRemaining(i, j + 1)) {
          return true;
        }
        _sudoku[i][j] = 0;
      }
    }
    return false;
  }

  bool _isValid(int row, int col, int num) {
    return _isRowValid(row, num) &&
        _isColValid(col, num) &&
        _isBoxValid(row, col, num);
  }

  bool _isRowValid(int row, int num) {
    for (int col = 0; col < _size; col++) {
      if (_sudoku[row][col] == num) {
        return false;
      }
    }
    return true;
  }

  bool _isColValid(int col, int num) {
    for (int row = 0; row < _size; row++) {
      if (_sudoku[row][col] == num) {
        return false;
      }
    }
    return true;
  }

  bool _isBoxValid(int row, int col, int num) {
    int boxRowStart = row - row % _boxSize;
    int boxColStart = col - col % _boxSize;

    for (int i = 0; i < _boxSize; i++) {
      for (int j = 0; j < _boxSize; j++) {
        if (_sudoku[boxRowStart + i][boxColStart + j] == num) {
          return false;
        }
      }
    }
    return true;
  }

  void _copySolution() {
    for (int i = 0; i < _size; i++) {
      for (int j = 0; j < _size; j++) {
        _solution[i][j] = _sudoku[i][j];
      }
    }
  }

  void _removeNumbers() {
    // 初始化解谜所需移除的格子总数
    int targetRemoved = difficulty;
    int removed = 0;

    // 生成0到_size*_size-1的连续数字（代表所有格子的索引）
    List<int> allCells = List.generate(_size * _size, (index) => index);
    // 打乱格子顺序，确保随机性
    allCells.shuffle();

    // 遍历所有格子，尝试移除
    for (int cellIndex in allCells) {
      int row = cellIndex ~/ _size;
      int col = cellIndex % _size;

      // 如果当前格子已是空白，跳过
      if (_sudoku[row][col] == 0) continue;

      // 保存当前值用于可能的还原
      int tempValue = _sudoku[row][col];
      // 尝试移除该格子
      _sudoku[row][col] = 0;

      // 检查是否仍有唯一解
      List<List<int>> gridCopy = _copySudoku();
      int solutionCount = _countSolutions(gridCopy);

      if (solutionCount != 1) {
        // 解不唯一，还原格子值
        _sudoku[row][col] = tempValue;
      } else {
        // 解唯一，成功移除
        removed++;
        // 达到目标移除数量，提前退出
        if (removed == targetRemoved) {
          break;
        }
      }
    }

    // 如果实际移除数量小于目标，更新difficulty为实际值
    if (removed < targetRemoved) {
      difficulty = removed;
    }
  }

  List<List<int>> _copySudoku() {
    return _sudoku.map((row) => List<int>.from(row)).toList();
  }

  int _countSolutions(List<List<int>> grid) {
    // 使用DLX算法计算解的数量
    final solver = SudokuSolver(level: level);
    return solver.countSolutions(grid);
  }
}

// DLX算法实现数独求解
class SudokuSolver {
  final int level;
  late int _size;
  late int _boxSize;

  SudokuSolver({required this.level}) {
    _size = level * level;
    _boxSize = level;
  }

  int countSolutions(List<List<int>> grid) {
    // 将数独问题转换为精确覆盖问题
    List<List<int>> matrix = _createExactCoverMatrix(grid);
    final dlx = DLX(matrix);
    return dlx.countSolutions();
  }

  List<List<int>> solve(List<List<int>> grid) {
    List<List<int>> matrix = _createExactCoverMatrix(grid);
    final dlx = DLX(matrix);
    List<int> solution = dlx.findFirstSolution();

    if (solution.isEmpty) return [];

    return _convertSolutionToGrid(solution);
  }

  List<List<int>> _createExactCoverMatrix(List<List<int>> grid) {
    int constraints = 4 * _size * _size;
    int possibilities = _size * _size * _size;
    List<List<int>> matrix = List.generate(
      possibilities,
      (i) => List.filled(constraints, 0),
    );

    int row, col, num, idx = 0;

    for (row = 0; row < _size; row++) {
      for (col = 0; col < _size; col++) {
        for (num = 1; num <= _size; num++) {
          if (grid[row][col] != 0 && grid[row][col] != num) {
            idx++;
            continue;
          }

          // 行-列约束
          matrix[idx][row * _size + col] = 1;

          // 行-数约束
          matrix[idx][_size * _size + row * _size + (num - 1)] = 1;

          // 列-数约束
          matrix[idx][2 * _size * _size + col * _size + (num - 1)] = 1;

          // 宫-数约束
          int box = (row ~/ _boxSize) * _boxSize + (col ~/ _boxSize);
          matrix[idx][3 * _size * _size + box * _size + (num - 1)] = 1;

          idx++;
        }
      }
    }

    return matrix;
  }

  List<List<int>> _convertSolutionToGrid(List<int> solution) {
    List<List<int>> grid = List.generate(_size, (i) => List.filled(_size, 0));

    for (int val in solution) {
      int num = (val % _size) + 1;
      int pos = val ~/ _size;
      int row = pos ~/ _size;
      int col = pos % _size;
      grid[row][col] = num;
    }

    return grid;
  }
}

// DLX算法实现
class DLXNode {
  DLXNode? left, right, up, down;
  DLXNode? column;
  int row = -1;
  int size = 0;

  DLXNode();
}

class DLX {
  final List<List<int>> matrix;
  late DLXNode root;
  late List<DLXNode> columns;
  int solutionCount = 0;
  bool stopAfterFirst = false;

  DLX(this.matrix) {
    _buildMatrix();
  }

  void _buildMatrix() {
    int cols = matrix.isEmpty ? 0 : matrix[0].length;
    columns = List.generate(cols, (_) => DLXNode());

    // 初始化列节点
    for (int i = 0; i < cols; i++) {
      columns[i].left = i > 0 ? columns[i - 1] : columns.last;
      columns[i].right = i < cols - 1 ? columns[i + 1] : columns.first;
      columns[i].up = columns[i];
      columns[i].down = columns[i];
    }

    // 创建根节点
    root = DLXNode();
    root.right = columns.first;
    root.left = columns.last;
    columns.first.left = root;
    columns.last.right = root;

    // 添加行
    for (int i = 0; i < matrix.length; i++) {
      DLXNode? last;
      for (int j = 0; j < cols; j++) {
        if (matrix[i][j] == 1) {
          DLXNode node = DLXNode();
          node.row = i;
          node.column = columns[j];

          // 连接上下
          node.up = columns[j].up;
          node.down = columns[j];
          columns[j].up!.down = node;
          columns[j].up = node;

          // 连接左右
          if (last == null) {
            node.left = node;
            node.right = node;
          } else {
            node.left = last;
            node.right = last.right;
            last.right!.left = node;
            last.right = node;
          }

          last = node;
          columns[j].size++;
        }
      }
    }
  }

  int countSolutions({bool stopAfterFirst = false}) {
    this.stopAfterFirst = stopAfterFirst;
    solutionCount = 0;
    _search(0);
    return solutionCount;
  }

  List<int> findFirstSolution() {
    List<int> solution = [];
    _searchWithSolution(0, solution);
    return solution;
  }

  void _search(int k) {
    if (root.right == root) {
      solutionCount++;
      return;
    }

    DLXNode col = _chooseColumn();
    _cover(col);

    for (DLXNode row = col.down!; row != col; row = row.down!) {
      for (DLXNode node = row.right!; node != row; node = node.right!) {
        _cover(node.column!);
      }

      _search(k + 1);

      if (stopAfterFirst && solutionCount > 0) return;

      for (DLXNode node = row.left!; node != row; node = node.left!) {
        _uncover(node.column!);
      }
    }

    _uncover(col);
  }

  bool _searchWithSolution(int k, List<int> solution) {
    if (root.right == root) {
      return true;
    }

    DLXNode col = _chooseColumn();
    _cover(col);

    for (DLXNode row = col.down!; row != col; row = row.down!) {
      solution.add(row.row);

      for (DLXNode node = row.right!; node != row; node = node.right!) {
        _cover(node.column!);
      }

      if (_searchWithSolution(k + 1, solution)) {
        return true;
      }

      solution.removeLast();

      for (DLXNode node = row.left!; node != row; node = node.left!) {
        _uncover(node.column!);
      }
    }

    _uncover(col);
    return false;
  }

  DLXNode _chooseColumn() {
    int minSize = 0x7FFFFFFFFFFFFFFF; // 十六进制表示的int最大值 (2^63 - 1)
    DLXNode? chosen;

    for (DLXNode col = root.right!; col != root; col = col.right!) {
      if (col.size < minSize) {
        minSize = col.size;
        chosen = col;
      }
    }

    return chosen!;
  }

  void _cover(DLXNode col) {
    col.right!.left = col.left;
    col.left!.right = col.right;

    for (DLXNode row = col.down!; row != col; row = row.down!) {
      for (DLXNode node = row.right!; node != row; node = node.right!) {
        node.down!.up = node.up;
        node.up!.down = node.down;
        node.column!.size--;
      }
    }
  }

  void _uncover(DLXNode col) {
    for (DLXNode row = col.up!; row != col; row = row.up!) {
      for (DLXNode node = row.left!; node != row; node = node.left!) {
        node.column!.size++;
        node.down!.up = node;
        node.up!.down = node;
      }
    }

    col.right!.left = col;
    col.left!.right = col;
  }
}
