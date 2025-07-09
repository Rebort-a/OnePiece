import 'package:flutter/foundation.dart';

import '../00.common/game/gamer.dart';
import 'base.dart';

class GameStateNotifier extends ValueNotifier<GameState> {
  GameStateNotifier(super.value);

  void undoMove() {
    if (value.moveHistory.isEmpty) return;

    final lastMove = value.moveHistory.removeLast();
    value.board.grid[lastMove.row][lastMove.col] = null;
    value.currentPlayer = lastMove.player;
    value.winner = null;
    notifyListeners();
  }

  void resetGame() {
    value.reset();
    notifyListeners();
  }

  bool placePiece(int row, int col, GamerType player) {
    bool success = value.board.placePiece(row, col, player);
    notifyListeners();
    return success;
  }
}
