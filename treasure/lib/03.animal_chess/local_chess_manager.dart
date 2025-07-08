import '../00.common/game/gamer.dart';
import 'foundation_manager.dart';

class LoaclAnimalChessManager extends BaseAnimalChessManager {
  LoaclAnimalChessManager() {
    initializeGame();
  }

  @override
  void leavePage() {
    showChessResult(currentGamer.value == GamerType.rear);
  }
}
