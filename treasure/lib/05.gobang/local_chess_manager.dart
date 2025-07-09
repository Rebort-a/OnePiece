// local_chess_manager.dart
import '../00.common/game/gamer.dart';
import 'base.dart';
import 'foundation_manager.dart';

class LocalGomokuManager extends BaseGomokuManager {
  @override
  void placePiece(int row, int col) {
    if (gameState.value.winner != null) return;

    final state = gameState.value;
    final currentPlayer = state.currentPlayer;

    if (gameState.placePiece(row, col, currentPlayer)) {
      state.moveHistory.add(Piece(player: currentPlayer, row: row, col: col));

      if (checkWin(row, col, currentPlayer)) {
        endGame(currentPlayer);
      } else {
        // 切换玩家
        state.currentPlayer = currentPlayer.opponent;
      }
    }
  }

  void resetGame() {
    gameState.resetGame();
  }

  void undoMove() {
    gameState.undoMove();
  }
}
