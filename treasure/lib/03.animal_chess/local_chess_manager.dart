import '../00.common/game/gamer.dart';
import 'foundation_manager.dart';

class LoaclAnimalChessManager extends BaseManager {
  LoaclAnimalChessManager() {
    initializeGame();
  }

  @override
  void leaveRoom() {
    showChessResult(currentGamer.value == GamerType.rear);
  }
}
