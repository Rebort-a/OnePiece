// local_page.dart
import 'package:flutter/material.dart';
import '../00.common/widget/joystick_component.dart';
import '../00.common/widget/notifier_navigator.dart';
import '../00.common/widget/speed_button.dart';
import 'draw/draw.dart';
import 'local_manager.dart';

class LocalGreedySnakePage extends StatelessWidget {
  final manager = LocalManager();

  LocalGreedySnakePage({super.key});

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
        actions: [
          IconButton(
            icon: manager.paused
                ? const Icon(Icons.play_arrow)
                : const Icon(Icons.pause),
            onPressed: () {
              manager.paused = !manager.paused;
              manager.paused ? manager.pause() : manager.resume();
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: manager,
        builder: (context, _) => Stack(
          children: [
            NotifierNavigator(navigatorHandler: manager.pageNavigator),
            DrawRegion(
              identity: manager.identity,
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
      ),
    );
  }
}
