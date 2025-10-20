/// 游戏常量
class Constants {
  // 世界参数
  static const double blockSize = 1;
  static const double blockSizeHalf = 0.5;

  // 物理参数
  static const double gravity = 9.8;
  static const double maxFallSpeed = 20.0;
  static const double friction = 0.8;

  // 玩家参数
  static const double playerWidth = 0.6;
  static const double playerHeight = 1.8;

  // 控制参数
  static const double moveSpeed = 1.0;
  static const double jumpStrength = 5.0;
  static const double touchSensitivity = 0.005;
  static const double mouseSensitivity = 0.002;
  static const double pitchLimit = 0.8;

  // 性能参数
  static const double minDeltaTime = 0.004;
  static const double maxDeltaTime = 0.02;
  static const double renderDistance = 8;

  // 渲染参数
  static const double nearClip = 0.1;
  static const double farClip = 50.0;
  static const double fieldOfView = 60.0; // 度
  static const double focalLength = 300.0;
}
