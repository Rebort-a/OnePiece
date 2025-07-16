import 'package:flutter/material.dart';

import '../00.common/game/step.dart';
import '../00.common/network/network_room.dart';
import '../00.common/widget/notifier_navigator.dart';
import 'net_manager.dart';
import 'foundation_widget.dart';

class NetGreedySnakePage extends StatelessWidget {
  final NetManager manager;

  NetGreedySnakePage({
    super.key,
    required RoomInfo roomInfo,
    required String userName,
  }) : manager = NetManager(roomInfo: roomInfo, userName: userName);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameStep>(
      valueListenable: manager.engine.gameStep,
      builder: (_, step, __) {
        return step == GameStep.action
            ? GameScreen(manager: manager, showStateButton: false)
            : _waitingScreen(step);
      },
    );
  }

  Widget _waitingScreen(GameStep step) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: manager.leavePage,
        ),
        title: const Text('Wait'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NotifierNavigator(navigatorHandler: manager.pageNavigator),
            if (step != GameStep.gameOver) const SizedBox(height: 20),
            if (step != GameStep.gameOver) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(step.getExplaination()),
          ],
        ),
      ),
    );
  }
}
