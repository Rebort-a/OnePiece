import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import '../00.common/utils/custom_notifier.dart';

import 'base.dart';
import 'extension.dart';

class BasePage extends StatelessWidget {
  final ListNotifier<GridNotifier> displayMap;
  final int boardSize;
  final Function(int) onGridSelected;

  const BasePage({
    super.key,
    required this.displayMap,
    required this.boardSize,
    required this.onGridSelected,
  });

  @override
  Widget build(BuildContext context) => _buildBody();

  Widget _buildBody() => _buildChessBoard();

  Widget _buildChessBoard() => AspectRatio(
    aspectRatio: 1,
    child: Center(
      child: Container(
        decoration: _boardDecoration(),
        child: ValueListenableBuilder(
          valueListenable: displayMap,
          builder: (_, gridNotifiers, __) => LayoutBuilder(
            builder: (context, constraints) {
              final size = _calculateBoardSize(constraints, boardSize);
              return SizedBox(
                width: size,
                height: size,
                child: _buildBoardGrid(),
              );
            },
          ),
        ),
      ),
    ),
  );

  BoxDecoration _boardDecoration() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Colors.brown, width: 8),
  );

  double _calculateBoardSize(BoxConstraints constraints, int boardSize) {
    final double maxSize = constraints.maxWidth;
    return (maxSize ~/ boardSize) * boardSize.toDouble();
  }

  Widget _buildBoardGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: boardSize,
      ),
      itemCount: displayMap.length,
      itemBuilder: (_, index) => _buildGridCell(displayMap.value[index]),
    );
  }

  Widget _buildGridCell(GridNotifier notifier) => ValueListenableBuilder(
    valueListenable: notifier,
    builder: (_, grid, __) => GestureDetector(
      onTap: () => onGridSelected(grid.coordinate),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: _gridDecoration(grid),
        child: grid.hasAnimal ? _buildAnimal(grid.animal!) : null,
      ),
    ),
  );

  BoxDecoration _gridDecoration(Grid grid) => BoxDecoration(
    color: _gridColor(grid),
    border: _gridBorder(grid),
    borderRadius: BorderRadius.circular(4),
  );

  Color _gridColor(Grid grid) {
    return switch (grid.type) {
      GridType.river => Colors.blue[200]!,
      GridType.tree => Colors.brown[400]!,
      _ => Colors.grey[100]!,
    };
  }

  Border _gridBorder(Grid grid) =>
      Border.all(color: _borderColor(grid), width: _borderWidth(grid));

  Color _borderColor(Grid grid) {
    if (grid.hasAnimal && grid.animal!.isSelected) return Colors.yellow;
    if (grid.isHighlighted) return Colors.green;
    return Colors.grey;
  }

  double _borderWidth(Grid grid) {
    if (grid.isHighlighted) return 4.0;
    if (grid.hasAnimal && grid.animal!.isSelected) return 3.0;
    return 1.0;
  }

  Widget _buildAnimal(Animal animal) => Container(
    margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: _animalColor(animal),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Center(
      child: Text(_animalContent(animal), style: const TextStyle(fontSize: 32)),
    ),
  );

  Color _animalColor(Animal animal) {
    return animal.isHidden
        ? Colors.blueGrey
        : (animal.owner == GamerType.front ? Colors.red : Colors.blue);
  }

  String _animalContent(Animal animal) {
    return animal.isHidden ? "" : animalEmojis[animal.type.index];
  }
}
