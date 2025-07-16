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
    return Stack(
      children: [
        // 游戏主绘制区域（根据方向调整大小）
        AnimatedBuilder(
          animation: manager,
          builder: (context, _) {
            return DrawRegion(
              identity: manager.engine.identity,
              backgroundColor: Colors.black87,
              snakes: manager.snakes,
              foods: manager.foods,
            );
          },
        ),

        // 导航通知组件
        NotifierNavigator(navigatorHandler: manager.pageNavigator),

        // 左上角：退出按钮
        Positioned(
          top: 40,
          left: 20,
          child: buildIconButton(
            icon: Icons.arrow_back,
            onPressed: manager.leavePage,
          ),
        ),

        // 左下角：摇杆
        Positioned(
          left: 20,
          bottom: 40,
          child: Joystick(onDirectionChanged: manager.updatePlayerAngle),
        ),

        // 右下角：加速按钮
        Positioned(
          right: 20,
          bottom: 40,
          child: SpeedButton(onSpeedChanged: manager.updatePlayerSpeed),
        ),
      ],
    );
  }

  // 构建统一风格的悬浮按钮
  Widget buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(25),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: 25,
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
