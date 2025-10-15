/// 游戏常量
class Constants {
  // 数学精度
  static const double epsilon = 0.001;

  // 物理参数
  static const double gravity = 9.8;
  static const double maxFallSpeed = 20.0;

  // 玩家参数
  static const double playerWidth = 0.6;
  static const double playerHeight = 1.8;

  // 控制参数
  static const double moveSpeed = 2.0;
  static const double jumpStrength = 5.0;
  static const double touchSensitivity = 0.005;
  static const double mouseSensitivity = 0.002;
  static const double pitchLimit = 0.8; // 弧度

  // 性能参数
  static const double minDeltaTime = 0.004;
  static const double maxDeltaTime = 0.02;
  static const double renderDistance = 20.0;

  // 渲染参数
  static const double nearClip = 0.1;
  static const double farClip = 50.0;
  static const double fieldOfView = 60.0; // 度
  static const double focalLength = 300.0;
}
