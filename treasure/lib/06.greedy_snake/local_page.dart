import 'package:flutter/material.dart';

import '../00.common/widget/joystick_component.dart';
import '../00.common/widget/notifier_navigator.dart';
import '../00.common/widget/speed_button.dart';
import 'draw/draw.dart';
import 'local_manager.dart';

class LocalGreedySnakePage extends StatelessWidget {
  final BaseManager manager = BaseManager();
  LocalGreedySnakePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Greedy Snake')),
      body: AnimatedBuilder(
        animation: manager,
        builder: (context, child) {
          return Stack(
            children: [
              NotifierNavigator(navigatorHandler: manager.pageNavigator),
              DrawRegion(
                backgroundColor: Colors.black87,
                snakes: manager.snakes,
                foods: manager.foods,
              ),
              // 游戏控制面板
              Positioned(
                left: 20,
                bottom: 20,
                child: Joystick(
                  onDirectionChanged: (angle) =>
                      manager.updatePlayerAngle(angle),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: SpeedButton(
                  onSpeedChanged: (isSpeeding) =>
                      manager.updatePlayerSpeed(isSpeeding),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
