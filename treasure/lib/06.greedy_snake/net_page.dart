// net_page.dart
import 'package:flutter/material.dart';
import '../00.common/game/step.dart';
import '../00.common/network/network_room.dart';
import '../00.common/widget/joystick_component.dart';
import '../00.common/widget/notifier_navigator.dart';
import '../00.common/widget/speed_button.dart';
import 'draw/draw.dart';
import 'net_manager.dart';

class NetGreedySnakePage extends StatelessWidget {
  final NetManager manager;

  NetGreedySnakePage({
    super.key,
    required RoomInfo roomInfo,
    required String userName,
  }) : manager = NetManager(roomInfo: roomInfo, userName: userName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: manager.leavePage,
        ),
        title: const Text('Greedy Snake'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<GameStep>(
        valueListenable: manager.engine.gameStep,
        builder: (_, step, __) {
          return step == GameStep.action ? _gameScreen() : _waitingScreen(step);
        },
      ),
    );
  }

  Widget _gameScreen() {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) => Stack(
        children: [
          NotifierNavigator(navigatorHandler: manager.pageNavigator),
          DrawRegion(
            identity: manager.engine.identity,
            backgroundColor: Colors.black87,
            snakes: manager.snakes,
            foods: manager.foods,
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: Joystick(onDirectionChanged: manager.updatePlayerAngle),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: SpeedButton(onSpeedChanged: manager.updatePlayerSpeed),
          ),
        ],
      ),
    );
  }

  Widget _waitingScreen(GameStep step) {
    return Center(
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
    );
  }
}
