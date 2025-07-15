import 'package:flutter/material.dart';

import '../00.common/widget/joystick_component.dart';
import '../00.common/widget/notifier_navigator.dart';
import '../00.common/widget/speed_button.dart';
import 'draw/draw.dart';
import 'local_manager.dart';

class LocalGreedySnakePage extends StatelessWidget {
  final LocalManager _manager = LocalManager();
  LocalGreedySnakePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Greedy Snake'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _manager.paused
                ? const Icon(Icons.play_arrow)
                : const Icon(Icons.pause),
            onPressed: () {
              _manager.paused = !_manager.paused;
              if (_manager.paused) {
                _manager.pause();
              } else {
                _manager.resume();
              }
            },
          ),
        ],
      ),

      body: AnimatedBuilder(
        animation: _manager,
        builder: (context, child) {
          return Stack(
            children: [
              NotifierNavigator(navigatorHandler: _manager.pageNavigator),
              DrawRegion(
                identity: _manager.identity,
                backgroundColor: Colors.black87,
                snakes: _manager.snakes,
                foods: _manager.foods,
              ),
              // 游戏控制面板
              Positioned(
                left: 20,
                bottom: 20,
                child: Joystick(
                  onDirectionChanged: (angle) =>
                      _manager.updatePlayerAngle(angle),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: SpeedButton(
                  onSpeedChanged: (isSpeeding) =>
                      _manager.updatePlayerSpeed(isSpeeding),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
