import 'dart:math';

import 'package:flutter/material.dart';
import 'base.dart';
import 'foundation_manager.dart';

class GoFoundationWidget extends StatelessWidget {
  final GoFoundationalManager manager;

  const GoFoundationWidget({super.key, required this.manager});

  @override
  Widget build(BuildContext context) => Center(child: _buildBoard());

  Widget _buildBoard() => AspectRatio(
    aspectRatio: 1.0,
    child: Center(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE6B87D),
          border: Border.all(color: const Color(0xFF8B4513), width: 2),
        ),
        child: ValueListenableBuilder(
          valueListenable: manager.board.grids,
          builder: (context, grids, _) {
            if (grids.isEmpty) {
              return const Text('棋盘数据为空');
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final double boardSize = _calculateBoardSize(
                  constraints,
                  manager.board.size,
                );
                final double cellSize = boardSize / manager.board.size;

                return SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: Stack(
                    children: [
                      // 绘制棋盘网格
                      _buildGridLines(cellSize, boardSize),
                      // 绘制星位
                      _buildStarPoints(cellSize),
                      // 绘制棋子
                      _buildStones(grids, cellSize),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );

  // 绘制网格线
  Widget _buildGridLines(double cellSize, double boardSize) {
    return CustomPaint(
      size: Size(boardSize, boardSize),
      painter: GridPainter(cellCount: manager.board.size, cellSize: cellSize),
    );
  }

  // 绘制星位（围棋棋盘上的小圆点）
  Widget _buildStarPoints(double cellSize) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: _getStarPositions().map((pos) {
            return Positioned(
              left: pos.dx * cellSize - 3,
              top: pos.dy * cellSize - 3,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 获取星位位置（19x19棋盘标准星位）
  List<Offset> _getStarPositions() {
    if (manager.board.size != 19) return [];
    return [
      const Offset(3, 3),
      const Offset(3, 9),
      const Offset(3, 15),
      const Offset(9, 3),
      const Offset(9, 9),
      const Offset(9, 15),
      const Offset(15, 3),
      const Offset(15, 9),
      const Offset(15, 15),
    ];
  }

  // 绘制棋子
  Widget _buildStones(List<GoGridNotifier> grids, double cellSize) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: manager.board.size,
        childAspectRatio: 1,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
      ),
      itemCount: grids.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildStone(grids[index], index, cellSize);
      },
    );
  }

  Widget _buildStone(GoGridNotifier notifier, int index, double cellSize) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, grid, __) {
        if (!grid.isEmpty()) {
          return Center(
            child: Container(
              width: cellSize * 0.85,
              height: cellSize * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: grid.isBlack() ? Colors.black : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 2,
                    offset: const Offset(1, 1),
                  ),
                ],
                border: grid.isWhite()
                    ? Border.all(color: Colors.black12, width: 1)
                    : null,
              ),
            ),
          );
        } else {
          return GestureDetector(
            onTap: () => manager.placePiece(index),
            child: Container(color: Colors.transparent),
          );
        }
      },
    );
  }

  double _calculateBoardSize(BoxConstraints constraints, int cellCount) {
    final double maxSize = min(constraints.maxWidth, constraints.maxHeight);
    return (maxSize ~/ cellCount) * cellCount.toDouble();
  }
}

// 棋盘绘制器
class GridPainter extends CustomPainter {
  final int cellCount;
  final double cellSize;

  GridPainter({required this.cellCount, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.0;

    // 绘制横线
    for (int i = 0; i < cellCount; i++) {
      double y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制竖线
    for (int i = 0; i < cellCount; i++) {
      double x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return cellCount != oldDelegate.cellCount ||
        cellSize != oldDelegate.cellSize;
  }
}
