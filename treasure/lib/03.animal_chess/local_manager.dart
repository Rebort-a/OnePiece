import '../00.common/game/gamer.dart';
import 'foundation_manager.dart';

class LoaclManager extends FoundationalManager {
  LoaclManager() {
    initGame();
  }

  @override
  void leavePage() {
    showChessResult(currentGamer.value == TurnGamerType.rear);
  }
}
