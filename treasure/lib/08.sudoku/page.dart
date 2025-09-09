import 'package:flutter/material.dart';

import '../00.common/component/notifier_navigator.dart';
import 'base.dart';
import 'manager.dart';

class SudokuPage extends StatelessWidget {
  final Manager _manager = Manager();

  SudokuPage({super.key});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) {
      _manager.leavePage();
    },
    child: _buildPage(),
  );

  Widget _buildPage() {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Sudoku'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _manager.leavePage,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _manager.resetGame,
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: _manager.showSelector,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        NotifierNavigator(navigatorHandler: _manager.pageNavigator),
        Expanded(flex: 1, child: _buildDisplayArea()),
        Expanded(flex: 8, child: _buildBoardArea()),
        Expanded(flex: 4, child: _buildInputArea()),
      ],
    );
  }

  /// 构建计时器组件
  Widget _buildDisplayArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<String>(
        valueListenable: _manager.displayInfo,
        builder: (_, info, __) => Text(
          info,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBoardArea() => Center(
    child: AspectRatio(
      aspectRatio: 1,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: ValueListenableBuilder(
            valueListenable: _manager.cells,
            builder: (_, cells, __) => LayoutBuilder(
              builder: (context, constraints) {
                final size = _calculateBoardSize(
                  constraints,
                  _manager.boardSize,
                );
                return SizedBox(
                  width: size,
                  height: size,
                  child: GridView.count(
                    crossAxisCount: _manager.boardSize,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: List.generate(
                      _manager.boardSize * _manager.boardSize,
                      (index) => CellWidget(
                        cell: cells[index],
                        boardLevel: _manager.boardLevel,
                        onTap: () {
                          _manager.selectCell(index);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  /// 计算棋盘尺寸
  double _calculateBoardSize(BoxConstraints constraints, int boardSize) {
    final double maxSize = constraints.maxWidth;
    return (maxSize ~/ boardSize) * boardSize.toDouble();
  }

  /// 构建数字输入区域
  Widget _buildInputArea() {
    return ValueListenableBuilder<int>(
      valueListenable: _manager.selectedCellIndex,
      builder: (context, index, _) {
        if (index == -1) return const SizedBox.shrink();

        if (_manager.selectedCell.type == CellType.fixed) {
          return const SizedBox.shrink();
        } else {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 3,
                  child: NumberCards(
                    cell: _manager.selectedCell,
                    onLock: _manager.checkCompleted,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: NumberKeyboard(cell: _manager.selectedCell),
                ),
                const Spacer(flex: 1),
              ],
            ),
          );
        }
      },
    );
  }
}

/// 单个单元格组件
class CellWidget extends StatelessWidget {
  final CellNotifier cell;
  final int boardLevel;
  final VoidCallback onTap;

  const CellWidget({
    super.key,
    required this.cell,
    required this.boardLevel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: cell,
      builder: (_, value, __) => Container(
        decoration: BoxDecoration(
          border: _buildCellBorder(cell.row, cell.col),
          color: _getCellBgColor(cell.row, cell.col),
        ),
        child: InkWell(onTap: onTap, child: _buildCellContent(cell)),
      ),
    );
  }

  /// 构建单元格边框
  Border _buildCellBorder(int row, int col) {
    final isBlockRight = (col + 1) % boardLevel == 0;
    final isBlockBottom = (row + 1) % boardLevel == 0;

    return Border(
      top: _buildBorderSide(row == 0, false),
      left: _buildBorderSide(col == 0, false),
      right: _buildBorderSide(isBlockRight, true),
      bottom: _buildBorderSide(isBlockBottom, true),
    );
  }

  /// 构建边框样式
  BorderSide _buildBorderSide(bool isBlockEdge, bool isInner) {
    return BorderSide(
      color: isBlockEdge ? Colors.black : Colors.grey[300]!,
      width: isBlockEdge ? 2 : 1,
    );
  }

  /// 获取单元格背景色
  Color _getCellBgColor(int row, int col) {
    if (cell.hint) return Colors.blue[50]!;
    final blockRow = row ~/ boardLevel;
    final blockCol = col ~/ boardLevel;
    return (blockRow + blockCol) % 2 == 0 ? Colors.grey[100]! : Colors.white;
  }

  /// 构建单元格内容
  Widget _buildCellContent(CellNotifier cellData) {
    switch (cellData.type) {
      case CellType.fixed:
        return _buildFixedCell(cellData.fixedDigit);
      case CellType.locked:
        return _buildLockedCell(cellData.fixedDigit);
      case CellType.editable:
        return _buildEditableCell(cellData.spareDigits);
    }
  }

  /// 构建固定单元格
  Widget _buildFixedCell(int digit) {
    return Center(
      child: Text(
        digit.toString(),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  /// 构建锁定单元格
  Widget _buildLockedCell(int digit) {
    return Center(
      child: Text(
        digit.toString(),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }

  /// 构建可编辑单元格
  Widget _buildEditableCell(List<int> digits) {
    if (digits.isEmpty) return const SizedBox.shrink();
    return _buildDigitGrid(digits);
  }

  /// 构建数字网格（候选数）
  Widget _buildDigitGrid(List<int> digits) {
    final crossAxisCount = digits.length <= 4 ? 2 : 3;
    final fontSize = digits.length <= 4 ? 14.0 : 9.0;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(crossAxisCount * crossAxisCount, (index) {
          if (index < digits.length) {
            return Center(
              child: Text(
                digits[index].toString(),
                style: TextStyle(fontSize: fontSize, color: Colors.blue),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ),
    );
  }
}

/// 已选数字卡片区域
class NumberCards extends StatelessWidget {
  final CellNotifier cell;
  final VoidCallback onLock;

  const NumberCards({super.key, required this.cell, required this.onLock});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SudokuCell>(
      valueListenable: cell,
      builder: (_, value, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 锁定/解锁按钮
                if (cell.canLock)
                  IconButton(
                    icon: const Icon(Icons.lock_open),
                    onPressed: () {
                      cell.lock();
                      onLock();
                    },
                  ),
                if (cell.type == CellType.locked)
                  IconButton(
                    icon: const Icon(Icons.lock),
                    onPressed: cell.unlock,
                  ),

                // 候选数字标签
                ...cell.spareDigits.map(
                  (int num) => _buildNumberChip(context, num),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建数字标签
  Widget _buildNumberChip(BuildContext context, int number) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: () => cell.removeDigit(number),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).primaryColor, width: 1),
          ),
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// 数字键盘组件
class NumberKeyboard extends StatelessWidget {
  final CellNotifier cell;

  const NumberKeyboard({super.key, required this.cell});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _buildKeyboardButton("CE", () => cell.clearDigits()),
          ...List.generate(
            9,
            (i) => _buildKeyboardButton(
              (i + 1).toString(),
              () => cell.addDigit(i + 1),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建键盘按钮
  Widget _buildKeyboardButton(String label, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 2,
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
