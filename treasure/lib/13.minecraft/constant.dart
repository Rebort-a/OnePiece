// 常量定义
class Constant {
  // 定理相关
  static const double epsilon = 0.001;
  // static const double epsilon = 1e-10;

  // 环境相关
  static const double gravity = 9.8;
  static const double maxFallSpeed = 20.0;

  // 玩家相关
  static const double playerWidth = 0.6;
  static const double playerHeight = 1.8;

  // 控制相关
  static const double moveSpeed = 50.0; // 移速
  static const double jumpForce = 5.0; // 跳跃力
  static const double touchSensitivity = 0.002; // 触摸灵敏度
  static const double pitchLimit = 0.47; // 约85度

  // 帧率相关
  static const double minDeltaTime = 0.004;
  static const double maxDeltaTime = 0.02;

  // 性能相关
  static const double renderDistance = 20.0;
}
