import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import '../00.common/game/direction.dart';
import '../00.common/utils/custom_notifier.dart';
import 'base.dart';
import 'extension.dart';

abstract class BaseManager {
  int boardSize = boardLevel * 2 + 1;

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});
  final ValueNotifier<GamerType> currentGamer = ValueNotifier(GamerType.front);
  final ListNotifier<GridNotifier> displayMap = ListNotifier([]);
  final List<int> _markedGrid = [];

  void initializeGame() {
    _setupBoard();
    _placePieces();
    _resetGameState();
  }

  void _setupBoard() {
    displayMap.value = List.generate(boardSize * boardSize, (index) {
      return GridNotifier(Grid(coordinate: index, type: _getGridType(index)));
    });
  }

  GridType _getGridType(int index) {
    final row = index ~/ boardSize;
    final col = index % boardSize;

    if (col == boardLevel) {
      if (row == boardLevel) return GridType.bridge;
      if (row == 0 || row == boardSize - 1) return GridType.tree;
      return GridType.road;
    }

    return row == boardLevel ? GridType.river : GridType.land;
  }

  void _placePieces() {
    final landPositions = _getLandPositions()..shuffle();
    const pieces = AnimalType.values;

    void placePlayerPieces(GamerType player) {
      for (int i = 0; i < pieces.length; i++) {
        final index = landPositions.removeLast();
        displayMap.value[index].placeAnimal(
          Animal(type: pieces[i], owner: player),
        );
      }
    }

    placePlayerPieces(GamerType.front);
    placePlayerPieces(GamerType.rear);
  }

  List<int> _getLandPositions() {
    return displayMap.value
        .asMap()
        .entries
        .where((entry) => entry.value.value.type == GridType.land)
        .map((entry) => entry.key)
        .toList();
  }

  void _resetGameState() {
    _markedGrid.clear();
    currentGamer.value = GamerType.front;
  }

  void selectGrid(int index) {
    final grid = displayMap.value[index].value;

    // 如果没有翻面，那么翻面
    if (grid.hasAnimal && grid.animal!.isHidden) {
      _revealPiece(index);
      return;
    }

    // 如果是选中棋子，那么取消棋子和周边的标记
    if (_isSelected(index)) {
      _clearSelectionAndHighlight();
      return;
    }

    // 如果是可选的移动目标，那么移动棋子
    if (_isValidMoveTarget(index)) {
      _movePiece(_markedGrid.first, index);
      return;
    }

    // 如果上面都不是，那么判断是否可以选中棋子
    if (_canSelect(grid)) {
      _setSelection(index);
    }
  }

  void _revealPiece(int index) {
    displayMap.value[index].revealAnimal();
    _endTurn();
  }

  void _clearSelectionAndHighlight() {
    if (_markedGrid.isEmpty) return;

    displayMap.value[_markedGrid.first].toggleSelection(false);

    for (final index in _markedGrid.skip(1)) {
      displayMap.value[index].toggleHighlight(false);
    }

    _markedGrid.clear();
  }

  bool _isValidMoveTarget(int index) {
    return _markedGrid.length > 1 && _markedGrid.skip(1).contains(index);
  }

  void _movePiece(int from, int to) {
    final fromGrid = displayMap.value[from].value;
    if (!fromGrid.hasAnimal) return;

    final movingAnimal = fromGrid.animal!;

    if (displayMap.value[to].value.hasAnimal) {
      _resolveCombat(movingAnimal, displayMap.value[to].value.animal!, to);
    } else {
      displayMap.value[to].placeAnimal(movingAnimal);
      _markedGrid.first = to;
    }

    displayMap.value[from].clearAnimal();
    _endTurn();
  }

  void _resolveCombat(Animal attacker, Animal defender, int targetPos) {
    final attackerWins = attacker.canEat(defender);
    final defenderWins = defender.canEat(attacker);

    if (attackerWins && defenderWins) {
      displayMap.value[targetPos].clearAnimal();
    } else if (attackerWins) {
      displayMap.value[targetPos].placeAnimal(attacker);
      _markedGrid.first = targetPos;
    }
  }

  bool _canSelect(Grid grid) {
    return grid.hasAnimal && grid.animal!.owner == currentGamer.value;
  }

  void _setSelection(int index) {
    _clearSelectionAndHighlight();
    _markedGrid.add(index);
    displayMap.value[index].toggleSelection(true);
    _calculatePossibleMoves(index);
  }

  void _calculatePossibleMoves(int index) {
    final row = index ~/ boardSize;
    final col = index % boardSize;

    for (final (dr, dc) in around) {
      final newRow = row + dr;
      final newCol = col + dc;
      final newIndex = newRow * boardSize + newCol;

      if (newRow >= 0 &&
          newRow < boardSize &&
          newCol >= 0 &&
          newCol < boardSize) {
        if (_isValidMove(index, newIndex)) {
          displayMap.value[newIndex].toggleHighlight(true);
          _markedGrid.add(newIndex);
        }
      }
    }
  }

  bool _isValidMove(int fromIndex, int toIndex) {
    final fromGrid = displayMap.value[fromIndex].value;
    final toGrid = displayMap.value[toIndex].value;

    if (!fromGrid.hasAnimal) return false;
    if (toGrid.animal?.isHidden == true) return false;
    if (toGrid.hasAnimal && toGrid.animal!.owner == fromGrid.animal!.owner) {
      return false;
    }

    return fromGrid.animal!.canMoveTo(fromGrid.type, toGrid.type);
  }

  void _endTurn() {
    _clearSelectionAndHighlight();
    currentGamer.value = currentGamer.value.opponent;
    _checkGameEnd();
  }

  void _checkGameEnd() {
    int redCount = 0, blueCount = 0;

    for (final gridNotifier in displayMap.value) {
      final animal = gridNotifier.value.animal;
      if (animal != null) {
        animal.owner == GamerType.front ? redCount++ : blueCount++;
      }
    }

    if (redCount == 0) {
      showChessResult(false);
    } else if (blueCount == 0) {
      showChessResult(true);
    }
  }

  bool _isSelected(int index) =>
      _markedGrid.isNotEmpty && _markedGrid.first == index;

  void showChessResult(bool isRedWin) {
    pageNavigator.value = (context) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("游戏结束"),
            content: Text("${isRedWin ? "红" : "蓝"}方获胜！"),
            actions: buildDialogActions(context),
          );
        },
      );
    };
  }

  List<Widget> buildDialogActions(BuildContext context) {
    return [
      TextButton(
        child: const Text('退出'),
        onPressed: () {
          Navigator.of(context).pop();
          _navigateToBack();
        },
      ),
      TextButton(
        child: const Text('重开'),
        onPressed: () {
          Navigator.of(context).pop();
          _restart();
        },
      ),
      TextButton(
        child: const Text('取消'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ];
  }

  void _restart() {
    initializeGame();
  }

  void leaveChess() {
    _navigateToBack();
  }

  void _navigateToBack() {
    pageNavigator.value = (context) {
      Navigator.of(context).pop();
    };
  }
}
