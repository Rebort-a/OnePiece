import 'package:flutter/material.dart';

import 'base.dart';
import 'manager.dart';

class SoftPage extends StatelessWidget {
  final _manager = Manager();

  SoftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    return AnimatedBuilder(
      animation: _manager,
      builder: (_, __) {
        return Stack(
          children: [
            // 渲染层
            CustomPaint(
              painter: SoftCylinderPainter(cylinder: _manager.soft),
              size: Size.infinite,
            ),

            // 手势控制
            GestureDetector(
              onScaleUpdate: (details) => _manager.handleScale(details),
              onTapDown: (_) => _manager.resetSoft(),
            ),

            // 键盘监听
            KeyboardListener(
              focusNode: _manager.focusNode,
              onKeyEvent: _manager.handleKeyEvent,
              child: const SizedBox.expand(),
            ),
          ],
        );
      },
    );
  }
}
