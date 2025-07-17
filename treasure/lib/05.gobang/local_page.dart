import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import 'local_manager.dart';
import 'foundation_widget.dart';

class LocalGomokuPage extends StatefulWidget {
  const LocalGomokuPage({super.key});

  @override
  State<LocalGomokuPage> createState() => _LocalGomokuPageState();
}

class _LocalGomokuPageState extends State<LocalGomokuPage> {
  late final LocalManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = LocalManager();
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
            onPressed: _manager.restart,
          ),
          IconButton(icon: const Icon(Icons.undo), onPressed: _manager.undo),
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<TurnGamerType>(
            valueListenable: _manager.board.currentGamer,
            builder: (context, gamer, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _manager.board.gameOver == false
                      ? '当前回合: ${gamer == TurnGamerType.front ? "黑方" : "白方"}'
                      : '${gamer == TurnGamerType.rear ? "黑方" : "白方"}获胜!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          Expanded(child: FoundationalWidget(manager: _manager)),
        ],
      ),
    );
  }
}
