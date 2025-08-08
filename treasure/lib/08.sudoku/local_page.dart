import 'package:flutter/material.dart';

import '../00.common/widget/notifier_navigator.dart';
import 'base.dart';
import 'local_manager.dart';

class SudokuPage extends StatelessWidget {
  final SudokuManager manager = SudokuManager();

  SudokuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: manager.reset),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: manager.showSelector,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            NotifierNavigator(navigatorHandler: manager.pageNavigator),
            // 顶部区域
            Expanded(flex: 1, child: _buildTop()),

            // 数独棋盘
            Expanded(flex: 5, child: SudokuBoardView(manager: manager)),

            // 底部区域
            Expanded(flex: 2, child: _buildBottom()),
          ],
        ),
      ),
    );
  }

  Widget _buildTop() {
    // 显示计时器
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: AnimatedBuilder(
          animation: manager,
          builder: (context, _) {
            return Text(
              manager.displayString,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottom() {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final selectedCell = manager.selectedCell;

        if (selectedCell == null || selectedCell.value.type == CellType.fixed) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
              // 数字卡片
              Expanded(flex: 1, child: NumberCards(manager: manager)),

              // 数字键盘
              Expanded(flex: 2, child: NumberKeyboard(manager: manager)),
            ],
          ),
        );
      },
    );
  }
}

// 数独棋盘视图
class SudokuBoardView extends StatelessWidget {
  final SudokuManager manager;

  const SudokuBoardView({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: AnimatedBuilder(
            animation: manager,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final double size = _calculateBoardSize(
                    constraints,
                    manager.boardSize,
                  );
                  return SizedBox(
                    width: size,
                    height: size, // 强制网格尺寸为计算出的精确值
                    child: GridView.count(
                      crossAxisCount: manager.boardSize,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      children: List.generate(
                        manager.boardSize * manager.boardSize,
                        (index) {
                          final row = index ~/ manager.boardSize;
                          final col = index % manager.boardSize;
                          final cell = manager.cells[row][col];

                          return CellWidget(
                            cell: cell,
                            boardLevel: manager.boardLevel,
                            isSelected: manager.selectedCell == cell,
                            onTap: () => manager.selectCell(cell),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  double _calculateBoardSize(BoxConstraints constraints, int boardSize) {
    final double maxSize = constraints.maxWidth;
    return (maxSize ~/ boardSize) * boardSize.toDouble();
  }
}

// 单个单元格组件
class CellWidget extends StatelessWidget {
  final CellNotifier cell;
  final int boardLevel;
  final bool isSelected;
  final VoidCallback onTap;

  const CellWidget({
    super.key,
    required this.cell,
    required this.boardLevel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: cell,
      builder: (_, value, __) {
        // 计算区块位置
        final blockRow = (value.row ~/ boardLevel);
        final blockCol = (value.col ~/ boardLevel);
        final isBlockBorderBottom = (value.row + 1) % boardLevel == 0;
        final isBlockBorderRight = (value.col + 1) % boardLevel == 0;

        // 边框设置
        final border = Border(
          top: BorderSide(
            color: value.row == 0 ? Colors.black : Colors.grey[300]!,
            width: value.row == 0 ? 2 : 1,
          ),
          left: BorderSide(
            color: value.col == 0 ? Colors.black : Colors.grey[300]!,
            width: value.col == 0 ? 2 : 1,
          ),
          right: BorderSide(
            color: isBlockBorderRight ? Colors.black : Colors.grey[300]!,
            width: isBlockBorderRight ? 2 : 1,
          ),
          bottom: BorderSide(
            color: isBlockBorderBottom ? Colors.black : Colors.grey[300]!,
            width: isBlockBorderBottom ? 2 : 1,
          ),
        );

        // 背景色
        Color bgColor;
        if (isSelected) {
          bgColor = Colors.blue[50]!;
        } else if ((blockRow + blockCol) % 2 == 0) {
          bgColor = Colors.grey[100]!;
        } else {
          bgColor = Colors.white;
        }

        return Container(
          decoration: BoxDecoration(border: border, color: bgColor),
          child: InkWell(onTap: onTap, child: _buildCellContent(value)),
        );
      },
    );
  }

  Widget _buildCellContent(SudokuCell cellData) {
    switch (cellData.type) {
      case CellType.fixed:
        return Center(
          child: Text(
            cellData.fixedDigit.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        );

      case CellType.locked:
        return Center(
          child: Text(
            cellData.fixedDigit.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
        );

      case CellType.editable:
        if (cellData.spareDigits.isEmpty) {
          return const SizedBox.shrink();
        }

        // 单个数字显示
        if (cellData.spareDigits.length == 1) {
          return Center(
            child: Text(
              cellData.spareDigits.first.toString(),
              style: TextStyle(
                fontSize: 20,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        // 多个数字网格显示
        return Padding(
          padding: const EdgeInsets.all(2),
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            children: List.generate(9, (index) {
              final num = index + 1;
              final hasNum = cellData.spareDigits.contains(num);

              return Center(
                child: Text(
                  hasNum ? num.toString() : "",
                  style: TextStyle(
                    fontSize: 10,
                    color: hasNum ? Colors.grey[600] : Colors.transparent,
                  ),
                ),
              );
            }),
          ),
        );
    }
  }
}

class NumberCards extends StatelessWidget {
  final SudokuManager manager;

  const NumberCards({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ValueListenableBuilder(
        valueListenable: manager.selectedCell!,
        builder: (_, value, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                // 水平间距与NumberCards保持一致
                spacing: 8,
                // 垂直间距
                runSpacing: 8,
                // 子组件居中对齐
                alignment: WrapAlignment.center,
                children: value.spareDigits.map((number) {
                  // 使用圆角矩形Container替代Chip
                  return GestureDetector(
                    onTap: () => manager.removeDigit(number),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16), // 圆角矩形
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        number.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // 根据cell.enableLock显示lock按钮
              if (value.spareDigits.length == 1 &&
                  value.type == CellType.editable)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    onPressed: manager.lock,
                    icon: Icon(Icons.lock_open),
                  ),
                ),

              if (value.type == CellType.locked)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    onPressed: manager.unlock,
                    icon: Icon(Icons.lock),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// 数字键盘组件
class NumberKeyboard extends StatelessWidget {
  final SudokuManager manager;

  const NumberKeyboard({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    // 使用Padding控制整体边距，避免边缘紧贴
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      // 使用Wrap代替GridView，实现流式布局
      child: Wrap(
        // 水平间距与NumberCards保持一致
        spacing: 8,
        // 垂直间距
        runSpacing: 8,
        // 子组件居中对齐
        alignment: WrapAlignment.center,
        children: [
          // 清除按钮
          _buildKeyboardButton(
            label: "Clear",
            onTap: () {
              if (manager.selectedCell != null) {
                manager.selectedCell!.clearDigits();
              }
            },
          ),
          // 数字按钮 1-9
          ...List.generate(9, (index) {
            final number = index + 1;
            return _buildKeyboardButton(
              label: number.toString(),
              onTap: () => manager.addDigit(number),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKeyboardButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        // 按钮最小尺寸，确保数字按钮大小一致
        minimumSize: const Size(48, 48),
        // 去除固定形状，让按钮根据内容自适应
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        // 内边距控制按钮大小，与文字匹配
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 2,
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14, // 与NumberCards字体大小保持一致
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
