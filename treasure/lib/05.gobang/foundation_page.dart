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
          valueListenable: manager.gameState,
          builder: (context, state, child) {
            Board board = state.board;
            if (board.size == 0) {
              return const Center(child: Text('地图数据为空'));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final double boardSize = _calculateBoardSize(
                  constraints,
                  board.size,
                );
                final double cellSize = boardSize / board.size;

                return SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: board.size,
                      childAspectRatio: 1,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 0,
                    ),
                    itemCount: board.size * board.size,
                    itemBuilder: (context, index) {
                      final int row = index ~/ board.size;
                      final int col = index % board.size;
                      final piece = board.getPiece(row, col);

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 0.5),
                        ),
                        child: Center(
                          child: piece != null
                              ? Container(
                                  width: cellSize * 0.8,
                                  height: cellSize * 0.8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: piece == GamerType.front
                                        ? Colors.black
                                        : Colors.white,
                                    border: piece == GamerType.rear
                                        ? Border.all(
                                            color: Colors.black,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => manager.placePiece(row, col),
                                  child: Container(color: Colors.transparent),
                                ),
                        ),
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
}
