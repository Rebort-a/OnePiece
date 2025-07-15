import 'package:flutter/material.dart';

import '../00.common/game/step.dart';
import '../00.common/network/network_room.dart';
import '../00.common/widget/joystick_component.dart';
import '../00.common/widget/notifier_navigator.dart';
import '../00.common/widget/speed_button.dart';
import 'draw/draw.dart';
import 'net_manager.dart';

class NetGreedySnakePage extends StatelessWidget {
  late final NetManager _manager;

  NetGreedySnakePage({
    super.key,
    required RoomInfo roomInfo,
    required String userName,
  }) {
    _manager = NetManager(roomInfo: roomInfo, userName: userName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _manager.leavePage,
        ),
        title: Text('Greedy Snake'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder<GameStep>(
      valueListenable: _manager.netRealEngine.gameStep,
      builder: (__, step, _) {
        return Center(
          child: Column(
            children: [
              NotifierNavigator(navigatorHandler: _manager.pageNavigator),
              ...(step == GameStep.action
                  ? [Expanded(child: _buildScreen())]
                  : _buildPrepare(step)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPrepare(GameStep step) {
    return [
      const SizedBox(height: 20),
      const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text(step.getExplaination()),
    ];
  }

  Widget _buildScreen() {
    return AnimatedBuilder(
      animation: _manager,
      builder: (context, child) {
        return Stack(
          children: [
            DrawRegion(
              identity: _manager.netRealEngine.identity,
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
    );
  }
}
