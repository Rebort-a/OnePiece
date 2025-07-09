// foundation_manager.dart
import 'package:flutter/material.dart';
import 'package:treasure/05.gobang/extension.dart';

import '../00.common/game/gamer.dart';
import '../00.common/model/notifier.dart';
import 'base.dart';

abstract class BaseGomokuManager {
  final GameStateNotifier gameState = GameStateNotifier(
    GameState(board: Board(size: 15)),
  );
  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});

  void placePiece(int row, int col);

  bool checkWin(int row, int col, GamerType player) {
    final board = gameState.value.board;
    final directions = [
      [1, 0], // 水平
      [0, 1], // 垂直
      [1, 1], // 对角线
      [1, -1], // 反对角线
    ];

    for (var dir in directions) {
      int count = 1; // 当前位置已经有1个棋子

      // 正向检查
      for (int i = 1; i < 5; i++) {
        int r = row + dir[0] * i;
        int c = col + dir[1] * i;

        if (r < 0 || r >= board.size || c < 0 || c >= board.size) break;
        if (board.getPiece(r, c) != player) break;
        count++;
      }

      // 反向检查
      for (int i = 1; i < 5; i++) {
        int r = row - dir[0] * i;
        int c = col - dir[1] * i;

        if (r < 0 || r >= board.size || c < 0 || c >= board.size) break;
        if (board.getPiece(r, c) != player) break;
        count++;
      }

      if (count >= 5) return true;
    }

    return false;
  }

  void endGame(GamerType winner) {
    gameState.value.winner = winner;
    pageNavigator.value = (context) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("游戏结束"),
          content: Text("${winner == GamerType.front ? "黑方" : "白方"}获胜!"),
          actions: [
            TextButton(
              child: const Text('确定'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    };
  }
}
