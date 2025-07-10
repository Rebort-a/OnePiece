// local_main_page.dart
import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import 'local_chess_manager.dart';
import 'foundation_page.dart';

class LocalGomokuPage extends StatefulWidget {
  const LocalGomokuPage({super.key});

  @override
  State<LocalGomokuPage> createState() => _LocalGomokuPageState();
}

class _LocalGomokuPageState extends State<LocalGomokuPage> {
  late final LocalGomokuManager manager;

  @override
  void initState() {
    super.initState();
    manager = LocalGomokuManager();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('五子棋'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: manager.restart,
          ),
          IconButton(icon: const Icon(Icons.undo), onPressed: manager.undo),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<GamerType>(
            valueListenable: manager.board.currentGamer,
            builder: (context, gamer, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  manager.board.gameOver == false
                      ? '当前回合: ${gamer == GamerType.front ? "黑方" : "白方"}'
                      : '${gamer == GamerType.rear ? "黑方" : "白方"}获胜!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          Expanded(child: GomokuBoard(manager: manager)),
        ],
      ),
    );
  }
}
