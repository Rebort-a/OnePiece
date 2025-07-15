import 'package:flutter/material.dart';
import '../00.common/game/gamer.dart';
import 'base.dart';
import 'foundation_manager.dart';

class GomokuBoard extends StatelessWidget {
  final BaseGomokuManager manager;

  const GomokuBoard({super.key, required this.manager});

  @override
  Widget build(BuildContext context) => _buildMapRegion();

  Widget _buildMapRegion() => AspectRatio(
    aspectRatio: 1.0,
    child: Center(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDCB35C),
          border: Border.all(color: const Color(0xFFDCB35C), width: 8),
        ),
        child: ValueListenableBuilder(
          valueListenable: manager.board.grids,
          builder: (context, grids, child) {
            if (grids.isEmpty) {
              return const Center(child: Text('地图数据为空'));
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
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: manager.board.size,
                      childAspectRatio: 1,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                    ),
                    itemCount: grids.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 0.5),
                        ),
                        width: cellSize,
                        height: cellSize,
                        child: _buildPiece(grids[index], index, cellSize),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );

  double _calculateBoardSize(BoxConstraints constraints, int cellCount) {
    final double maxSize = constraints.maxWidth;
    return (maxSize ~/ cellCount) * cellCount.toDouble();
  }

  Widget _buildPiece(GridNotifier notifier, int index, double cellSize) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, grid, __) {
        if (grid.hasPiece()) {
          final TurnGamerType piece = TurnGamerType.values[grid.state];
          return Center(
            child: Container(
              width: cellSize * 0.8,
              height: cellSize * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: piece == TurnGamerType.front
                    ? Colors.black
                    : Colors.white,
                border: piece == TurnGamerType.rear
                    ? Border.all(color: Colors.black, width: 1.5)
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
}
