// net_main_page.dart
import 'package:flutter/material.dart';
import 'package:treasure/00.common/game/gamer.dart';

import '../00.common/game/step.dart';
import 'base.dart';
import 'foundation_page.dart';

import '../00.common/network/network_room.dart';
import 'net_chess_manager.dart';

class NetGomokuPage extends StatelessWidget {
  late final NetGomokuManager _manager;

  NetGomokuPage({
    super.key,
    required RoomInfo roomInfo,
    required String userName,
  }) {
    _manager = NetGomokuManager(roomInfo: roomInfo, userName: userName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网络五子棋'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _manager.netTurnEngine.leavePage,
        ),
      ),
      body: Column(
        children: [
          ValueListenableBuilder<GameState>(
            valueListenable: _manager.gameState,
            builder: (context, state, child) {
              return ValueListenableBuilder<TurnGameStep>(
                valueListenable: _manager.netTurnEngine.gameStep,
                builder: (context, step, child) {
                  if (step == TurnGameStep.action) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        state.winner == null
                            ? state.currentPlayer ==
                                      _manager.netTurnEngine.playerType
                                  ? "你的回合"
                                  : "对方回合"
                            : '${state.winner == GamerType.front ? "黑方" : "白方"}获胜!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        step.getExplaination(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
          Expanded(child: GomokuBoard(manager: _manager)),
        ],
      ),
    );
  }
}
