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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 游戏主绘制区域（根据方向调整大小）
          AnimatedBuilder(
            animation: manager,
            builder: (context, _) {
              return DrawRegion(
                identity: manager.identity,
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

          // 右上角：暂停/继续按钮
          Positioned(
            top: 40,
            right: 20,
            child: buildIconButton(
              icon: manager.paused ? Icons.play_arrow : Icons.pause,
              onPressed: () {
                manager.paused = !manager.paused;
                manager.paused ? manager.pause() : manager.resume();
              },
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
      ),
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
}
