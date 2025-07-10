// local_chess_manager.dart

import 'foundation_manager.dart';

class LocalGomokuManager extends BaseGomokuManager {
  @override
  void placePiece(int index) {
    board.placePiece(index);
  }
}
