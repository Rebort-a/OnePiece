import 'foundation_manager.dart';

class GoLocalManager extends GoFoundationalManager {
  @override
  void placePiece(int index) {
    if (!board.gameOver) {
      board.placeStone(index);
    }
  }

  void resign() {
    board.resign();
  }
}
