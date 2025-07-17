import 'package:flutter/material.dart';

import '../00.common/widget/joystick_component.dart';
import '../00.common/widget/notifier_navigator.dart';
import '../00.common/widget/speed_button.dart';
import 'draw_paint.dart';
import 'foundation_manager.dart';

class GameScreen extends StatelessWidget {
  final FoundationalManager manager;
  final bool showStateButton;

  const GameScreen({
    super.key,
    required this.manager,
    required this.showStateButton,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotifierNavigator(navigatorHandler: manager.pageNavigator),

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
        Positioned(
          top: 40,
          left: 20,
          child: _buildIconButton(
            icon: Icons.arrow_back,
            onPressed: manager.leavePage,
          ),
        ),
        if (showStateButton)
          ValueListenableBuilder(
            valueListenable: manager.gameState,
            builder: (context, state, child) {
              return Positioned(
                top: 40,
                right: 20,
                child: _buildIconButton(
                  icon: state ? Icons.pause : Icons.play_arrow,
                  onPressed: () => manager.toggleState(),
                ),
              );
            },
          ),
        Positioned(
          left: 20,
          bottom: 40,
          child: Joystick(onDirectionChanged: manager.updatePlayerAngle),
        ),
        Positioned(
          right: 20,
          bottom: 40,
          child: SpeedButton(onSpeedChanged: manager.updatePlayerSpeed),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
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
