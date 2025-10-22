/// 游戏常量
class Constants {
  // 世界参数
  static const double blockSize = 1;
  static const double blockSizeHalf = 0.5;
  static const double epsilon = 0.001;

  // 物理参数
  static const double gravity = 9.8;
  static const double maxFallSpeed = 20.0;
  static const double friction = 0.8;

  // 玩家参数
  static const double playerWidth = 0.6;
  static const double playerHeight = 1.8;

  // 控制参数
  static const double moveSpeed = 1.0;
  static const double jumpVelocity = 5.0;
  static const double touchSensitivity = 0.005;
  static const double mouseSensitivity = 0.002;
  static const double pitchLimit = 0.8;

  // 性能参数
  static const double minDeltaTime = 0.004;
  static const double maxDeltaTime = 0.02;
  static const double renderDistance = 8;
  static const double colliderDistance = 2;

  // 渲染参数
  static const double nearClip = 0.1;
  static const double farClip = 50.0;
  static const double fieldOfView = 60.0; // 度
  static const double focalLength = 300.0;

  // 区块参数
  static const int chunkSize = 16;
  static const int renderChunkDistance = 1;

  // 八叉树参数
  static const int maxBlocksPerNode = 4;
  static const double minHalfSize = 1.0;

  // 世界生成参数
  static const int worldHeightMin = 0;
  static const int worldHeightMax = 20;
  static const double treeProbability = 0.02;
  static const int minTrunkHeight = 3;
  static const int maxTrunkHeight = 4;
  static const int waterLevel = 15;
  static const bool enableCaves = true;

  // UI参数
  static const double joystickBaseRadius = 60;
  static const double joystickStickRadius = 30;
  static const double jumpButtonSize = 60;
  static const double crosshairSize = 20;
  static const double crosshairStroke = 2;
  static const double crosshairCrossSize = 8;

  // 调试参数
  static const double debugTextFontSize = 12;
  static const double debugTextOffset = 10;
}
