import 'package:flutter/material.dart';
import 'game_controller.dart';
import 'widgets/joystick.dart';
import 'widgets/speed_button.dart';
import 'widgets/game_background.dart';
import 'widgets/snake.dart';
import 'widgets/food.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      onGameOver: _handleGameOver,
      onScoreChanged: (score) {
        setState(() {});
      },
      onStateUpdated: () {
        setState(() {});
      },
    );
    _controller.startGame();
  }

  void _handleGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('游戏结束'),
          content: Text('得分: ${_controller.score}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _controller.resetGame();
                setState(() {});
              },
              child: const Text('再来一局'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('得分: ${_controller.score}'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GameBackground(controller: _controller),
          Snake(controller: _controller),
          Food(controller: _controller),
          // 游戏控制面板
          Positioned(
            left: 20,
            bottom: 20,
            child: Joystick(
              onDirectionChanged: (angle) {
                _controller.setDirection(angle);
              },
            ),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: SpeedButton(
              onSpeedChanged: (isSpeeding) {
                _controller.setSpeed(isSpeeding);
              },
            ),
          ),
        ],
      ),
    );
  }
}
