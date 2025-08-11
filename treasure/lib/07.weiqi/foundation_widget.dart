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
                      // 绘制棋盘网格（十字线）
                      _buildGridLines(cellSize, boardSize, manager.board.size),
                      // 绘制星位
                      _buildStarPoints(cellSize, manager.board.size),
                      // 绘制棋子（在线交叉点上）
                      _buildStones(grids, cellSize, manager.board.size),
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

  // 绘制网格线（改为十字线）
  Widget _buildGridLines(
    double cellSize,
    double boardSize,
    int boardSizeValue,
  ) {
    return CustomPaint(
      size: Size(boardSize, boardSize),
      painter: GridPainter(
        lineCount: boardSizeValue, // 线数等于棋盘大小
        cellSize: cellSize,
      ),
    );
  }

  // 绘制星位（围棋棋盘上的小圆点）
  Widget _buildStarPoints(double cellSize, int boardSizeValue) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: _getStarPositions(boardSizeValue).map((pos) {
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

  // 获取星位位置（根据棋盘大小计算）
  List<Offset> _getStarPositions(int boardSize) {
    if (boardSize != 19 && boardSize != 13 && boardSize != 9) return [];

    List<Offset> positions = [];
    if (boardSize == 19) {
      positions = [
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
    } else if (boardSize == 13) {
      positions = [
        const Offset(3, 3),
        const Offset(3, 9),
        const Offset(6, 6),
        const Offset(9, 3),
        const Offset(9, 9),
      ];
    } else if (boardSize == 9) {
      positions = [
        const Offset(2, 2),
        const Offset(2, 6),
        const Offset(4, 4),
        const Offset(6, 2),
        const Offset(6, 6),
      ];
    }
    return positions;
  }

  // 绘制棋子（调整为在线交叉点上）
  Widget _buildStones(
    List<GoGridNotifier> grids,
    double cellSize,
    int boardSize,
  ) {
    return Stack(
      children: List.generate(grids.length, (index) {
        return _buildStone(grids[index], index, cellSize, boardSize);
      }),
    );
  }

  Widget _buildStone(
    GoGridNotifier notifier,
    int index,
    double cellSize,
    int boardSize,
  ) {
    // 计算交叉点坐标
    int row = index ~/ boardSize;
    int col = index % boardSize;

    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, grid, __) {
        if (!grid.isEmpty()) {
          // 棋子绘制在线交叉点上
          return Positioned(
            left: col * cellSize - cellSize * 0.425,
            top: row * cellSize - cellSize * 0.425,
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
          // 点击区域覆盖交叉点周围
          return Positioned(
            left: col * cellSize - cellSize * 0.5,
            top: row * cellSize - cellSize * 0.5,
            width: cellSize,
            height: cellSize,
            child: GestureDetector(
              onTap: () => manager.placePiece(index),
              child: Container(color: Colors.transparent),
            ),
          );
        }
      },
    );
  }

  double _calculateBoardSize(BoxConstraints constraints, int cellCount) {
    final double maxSize = min(constraints.maxWidth, constraints.maxHeight);
    // 调整计算方式，考虑线数比格子数多1
    return (maxSize ~/ (cellCount - 1)) * (cellCount - 1).toDouble();
  }
}

// 棋盘绘制器（改为绘制十字线）
class GridPainter extends CustomPainter {
  final int lineCount; // 线的数量
  final double cellSize; // 线之间的间距

  GridPainter({required this.lineCount, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.0;

    // 绘制横线（lineCount条）
    for (int i = 0; i < lineCount; i++) {
      double y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制竖线（lineCount条）
    for (int i = 0; i < lineCount; i++) {
      double x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return lineCount != oldDelegate.lineCount ||
        cellSize != oldDelegate.cellSize;
  }
}
