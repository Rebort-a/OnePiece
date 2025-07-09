// net_chess_manager.dart
import 'dart:convert';

import '../00.common/game/gamer.dart';
import '../00.common/engine/net_turn_engine.dart';
import '../00.common/game/step.dart';
import '../00.common/network/network_message.dart';
import '../00.common/network/network_room.dart';
import 'foundation_manager.dart';
import 'base.dart';

class NetGomokuManager extends BaseGomokuManager {
  late final NetTurnGameEngine netTurnEngine;

  NetGomokuManager({required String userName, required RoomInfo roomInfo}) {
    netTurnEngine = NetTurnGameEngine(
      userName: userName,
      roomInfo: roomInfo,
      navigatorHandler: pageNavigator,
      searchHandler: _searchHandler,
      resourceHandler: _resourceHandler,
      actionHandler: _actionHandler,
      endHandler: _endHandler,
    );
  }

  void _searchHandler() {
    resetGame();
    netTurnEngine.sendNetworkMessage(
      MessageType.resource,
      jsonEncode({'type': 'ready'}),
    );
  }

  void _resourceHandler(TurnGameStep step, NetworkMessage message) {
    if (message.content == 'ready') {
      netTurnEngine.gameStep.value = TurnGameStep.action;
    }
  }

  void _actionHandler(bool isSelf, NetworkMessage message) {
    final data = jsonDecode(message.content);
    final row = data['row'];
    final col = data['col'];

    if (isSelf) {
      // 处理自己的动作
      _placePieceLocal(row, col);
    } else {
      // 处理对手的动作
      _placePieceLocal(row, col);
    }
  }

  void _placePieceLocal(int row, int col) {
    if (gameState.value.winner != null) return;

    final state = gameState.value;
    final currentPlayer = state.currentPlayer;

    if (gameState.placePiece(row, col, currentPlayer)) {
      state.moveHistory.add(Piece(player: currentPlayer, row: row, col: col));

      if (checkWin(row, col, currentPlayer)) {
        endGame(currentPlayer);
        netTurnEngine.sendNetworkMessage(
          MessageType.end,
          jsonEncode({
            'winner': currentPlayer == GamerType.front ? 'black' : 'white',
          }),
        );
      } else {
        state.currentPlayer = currentPlayer.opponent;
      }
    }
  }

  @override
  void placePiece(int row, int col) {
    if (gameState.value.currentPlayer == netTurnEngine.playerType) {
      netTurnEngine.sendNetworkMessage(
        MessageType.action,
        jsonEncode({'row': row, 'col': col}),
      );
    }
  }

  void _endHandler() {
    // 处理游戏结束
  }

  void resetGame() {
    gameState.resetGame();
  }

  void undoMove() {
    gameState.undoMove();
  }
}
