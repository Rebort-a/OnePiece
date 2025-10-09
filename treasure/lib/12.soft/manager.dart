import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'base.dart';

enum ForceDirection { up, down, left, right, outward, inward }

class Manager with ChangeNotifier implements TickerProvider {
  late Ticker _ticker;
  double _lastElapsed = 0; // 上次更新时间
  final FocusNode focusNode = FocusNode();

  SoftCylinder _soft = SoftCylinder(center: Vector3(0, 0, 300)); // 在焦点位置生成圆环
  Vector3 _externalForce = Vector3(0, 0, 0); // 所有粒子都受相同的外力

  double _lastScale = 1.0;

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  Manager() {
    _initFocusNote();
    _initTicker();
  }

  void _initFocusNote() {
    focusNode.requestFocus();
  }

  void _initTicker() {
    _ticker = createTicker(_update);
    _ticker.start();
  }

  void _update(Duration elapsed) {
    final currentTime = elapsed.inMilliseconds;

    final currentElapsed = currentTime / 1000.0;
    final deltaTime = currentElapsed - _lastElapsed;
    _lastElapsed = currentElapsed;

    final clampedDeltaTime = deltaTime.clamp(0.004, 0.02); // 限制帧率

    _soft.simulateStep(clampedDeltaTime, _externalForce);

    notifyListeners();
  }

  void resetSoft() {
    _externalForce = Vector3.zero(); // 清除外力
    _soft = SoftCylinder(center: Vector3(0, 0, 300)); // 在焦点位置生成圆环
  }

  /// 处理键盘事件
  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      switch (event.logicalKey) {
        // 上方向：上箭头、W/w
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.keyW:
          _changeExternalForce(ForceDirection.up);
          break;
        // 下方向：下箭头、S/s
        case LogicalKeyboardKey.arrowDown:
        case LogicalKeyboardKey.keyS:
          _changeExternalForce(ForceDirection.down);
          break;
        // 左方向：左箭头、A/a
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.keyA:
          _changeExternalForce(ForceDirection.left);
          break;
        // 右方向：右箭头、D/d
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.keyD:
          _changeExternalForce(ForceDirection.right);
          break;
        // 向外：O/o
        case LogicalKeyboardKey.keyO:
          _changeExternalForce(ForceDirection.outward);
          break;
        // 向内：I/i
        case LogicalKeyboardKey.keyI:
          _changeExternalForce(ForceDirection.inward);
          break;
      }
    }
  }

  void handleScale(ScaleUpdateDetails details) {
    const double scaleSensitivity = 0.8;
    const double dragSensitivity = 0.01;
    // 1. 处理平移（单指滑动）
    // details.focalPointDelta 包含了平移的偏移量（替代原来的 drag delta）
    if (details.focalPointDelta.dx != 0) {
      final direction = details.focalPointDelta.dx > 0
          ? ForceDirection.right
          : ForceDirection.left;
      _changeExternalForce(
        direction,
        sensitivity: dragSensitivity * details.focalPointDelta.dx.abs(),
      );
    }

    if (details.focalPointDelta.dy != 0) {
      final direction = details.focalPointDelta.dy > 0
          ? ForceDirection.down
          : ForceDirection.up;
      _changeExternalForce(
        direction,
        sensitivity: dragSensitivity * details.focalPointDelta.dy.abs(),
      );
    }

    // 2. 处理缩放（双指）
    final scaleDiff = details.scale - _lastScale;
    if (scaleDiff.abs() > 0.001) {
      final direction = scaleDiff > 0
          ? ForceDirection.outward
          : ForceDirection.inward;
      _changeExternalForce(
        direction,
        sensitivity: scaleSensitivity * scaleDiff.abs(),
      );
    }
    _lastScale = details.scale;
  }

  void _changeExternalForce(
    ForceDirection direction, {
    double sensitivity = 0.1,
  }) {
    switch (direction) {
      case ForceDirection.up:
        _externalForce += Vector3(0, sensitivity, 0);
        break;
      case ForceDirection.down:
        _externalForce += Vector3(0, -sensitivity, 0);
        break;
      case ForceDirection.left:
        _externalForce += Vector3(-sensitivity, 0, 0);
        break;
      case ForceDirection.right:
        _externalForce += Vector3(sensitivity, 0, 0);
        break;
      case ForceDirection.outward:
        _externalForce += Vector3(0, 0, -sensitivity);
        break;
      case ForceDirection.inward:
        _externalForce += Vector3(0, 0, sensitivity);
        break;
    }
  }

  SoftCylinder get soft => _soft;
}
