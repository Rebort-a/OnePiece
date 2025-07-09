import '../00.common/game/gamer.dart';

class Piece {
  final GamerType player;
  final int row;
  final int col;

  Piece({required this.player, required this.row, required this.col});
}

class Board {
  final int size;
  late List<List<GamerType?>> grid;

  Board({required this.size}) {
    grid = List.generate(size, (_) => List.filled(size, null));
  }

  bool placePiece(int row, int col, GamerType player) {
    if (grid[row][col] != null) return false;
    grid[row][col] = player;
    return true;
  }

  GamerType? getPiece(int row, int col) => grid[row][col];

  void clear() {
    grid = List.generate(size, (_) => List.filled(size, null));
  }
}

class GameState {
  final Board board;
  GamerType currentPlayer;
  GamerType? winner;
  List<Piece> moveHistory = [];

  GameState({required this.board, this.currentPlayer = GamerType.front});

  void reset() {
    board.clear();
    currentPlayer = GamerType.front;
    winner = null;
    moveHistory.clear();
  }
}
