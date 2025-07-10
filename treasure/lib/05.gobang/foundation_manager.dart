import 'base.dart';

abstract class BaseGomokuManager {
  final Board board = Board(size: 15);

  void placePiece(int index);

  void restart() {
    board.restart();
  }

  void undo() {
    board.undoMove();
  }
}
