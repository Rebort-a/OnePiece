/// 游戏常量
class Constants {
  // ============================
  // 世界基本参数
  // ============================

  /// 方块尺寸（单位：米）
  static const int blockSize = 1;

  /// 方块半尺寸（单位：米）
  static const double blockSizeHalf = 0.5;

  /// 浮点数比较容差（用于避免浮点精度问题）
  static const double epsilon = 0.001;

  // ============================
  // 物理参数
  // ============================

  /// 重力加速度（单位：米/秒²）
  static const double gravity = 9.8;

  /// 最大下落速度（单位：米/秒）
  static const double maxFallSpeed = 20.0;

  /// 地面摩擦系数（0-1，值越小摩擦越大）
  static const double friction = 0.8;

  // ============================
  // 玩家参数
  // ============================

  /// 玩家宽度（单位：米）
  static const double playerWidth = 0.6;

  /// 玩家高度（单位：米）
  static const double playerHeight = 1.8;

  // ============================
  // 控制参数
  // ============================

  /// 基础移动速度（单位：米/秒）
  static const double moveSpeed = 2.0;

  /// 跳跃初速度（单位：米/秒）
  static const double jumpVelocity = 5.0;

  /// 触摸灵敏度（用于移动设备）
  static const double touchSensitivity = 0.005;

  /// 鼠标灵敏度（用于桌面设备）
  static const double mouseSensitivity = 0.002;

  /// 俯仰角限制（弧度，防止视角翻转）
  static const double pitchLimit = 0.8;

  // ============================
  // 性能参数
  // ============================

  /// 最小帧时间（秒，防止过小的deltaTime导致计算频繁）
  static const double minDeltaTime = 0.004;

  /// 最大帧时间（秒，防止过大的deltaTime导致瞬移）
  static const double maxDeltaTime = 0.02;

  // ============================
  // 区块参数
  // ============================

  /// 区块尺寸（单位：方块数）
  static const int chunkSize = 16;

  /// 渲染区块距离（单位：区块数）
  static const int renderChunkDistance = 1;

  /// 渲染距离（单位：米）
  static const double renderDistance = 8;

  /// 碰撞检测距离（单位：米）
  static const double colliderDistance = 2;

  // ============================
  // 八叉树参数
  // ============================

  /// 每个节点最大方块数量
  static const int maxBlocksPerNode = 4;

  /// 最小节点半尺寸（单位：米）
  static const double minHalfSize = 1.0;

  /// 合并阈值除数（用于计算节点合并条件）
  static const int mergeThresholdDivisor = 3;

  /// 最小合并阈值
  static const int mergeThresholdMin = 1;

  // ============================
  // 渲染参数
  // ============================

  /// 近裁剪平面距离（单位：米）
  static const double nearClip = 0.1;

  /// 远裁剪平面距离（单位：米）
  static const double farClip = 1000.0;

  /// 垂直视野角度（单位：度）
  static const double fieldOfView = 60.0;

  /// 焦距（单位：米）
  static const double focalLength = 300.0;

  /// 背面光照系数（值越小越暗）
  static const double lightingBackFace = 0.8;

  /// 正面光照系数（值越大越亮）
  static const double lightingFrontFace = 1.2;

  /// 顶面光照系数（模拟天空光照）
  static const double lightingTopFace = 1.1;

  /// 底面光照系数（模拟地面反射）
  static const double lightingBottomFace = 0.9;

  /// 默认光照系数
  static const double lightingDefault = 1.0;

  /// NDC坐标缩放系数（标准化设备坐标）
  static const double ndcScale = 0.5;

  /// NDC坐标偏移量
  static const double ndcOffset = 0.5;

  /// 屏幕Y轴翻转（1.0为正常，-1.0为翻转）
  static const double screenYFlip = 1.0;

  // ============================
  // 世界生成参数
  // ============================

  /// 世界最小高度（单位：方块数）
  static const int worldHeightMin = 0;

  /// 世界最大高度（单位：方块数）
  static const int worldHeightMax = 20;

  /// 树干最小高度（单位：方块数）
  static const int minTrunkHeight = 3;

  /// 树干最大高度（单位：方块数）
  static const int maxTrunkHeight = 4;

  /// 地形噪声缩放系数1（大尺度地形）
  static const double terrainNoiseScale1 = 0.01;

  /// 地形噪声缩放系数2（中尺度地形）
  static const double terrainNoiseScale2 = 0.05;

  /// 地形噪声缩放系数3（小尺度细节）
  static const double terrainNoiseScale3 = 0.1;

  /// 地形噪声振幅1（大尺度地形影响程度）
  static const double terrainNoiseAmplitude1 = 8;

  /// 地形噪声振幅2（中尺度地形影响程度）
  static const double terrainNoiseAmplitude2 = 4;

  /// 地形噪声振幅3（小尺度细节影响程度）
  static const double terrainNoiseAmplitude3 = 2;

  /// 树木生成概率（0-1，值越大树木越多）
  static const double treeProbability = 0.02;

  /// 树冠半径（单位：方块数）
  static const int treeCanopyRadius = 2;

  /// 树冠高度（单位：方块数）
  static const int treeCanopyHeight = 3;

  /// 树冠密度（值越大树叶越密集）
  static const int treeCanopyDensity = 3;

  /// 最大随机种子值
  static const int maxRandomSeed = 0x7FFFFFFF;

  /// 噪声哈希乘数1（用于噪声函数）
  static const int noiseHashMultiplier1 = 73856093;

  /// 噪声哈希乘数2（用于噪声函数）
  static const int noiseHashMultiplier2 = 19349663;

  // ============================
  // UI参数
  // ============================

  /// 摇杆底座半径（单位：像素）
  static const double joystickBaseRadius = 60;

  /// 摇杆手柄半径（单位：像素）
  static const double joystickStickRadius = 30;

  /// 跳跃按钮尺寸（单位：像素）
  static const double jumpButtonSize = 60;

  /// 十字准星尺寸（单位：像素）
  static const double crosshairSize = 20;

  /// 十字准星线条粗细（单位：像素）
  static const double crosshairStroke = 2;

  /// 十字准星交叉部分尺寸（单位：像素）
  static const double crosshairCrossSize = 8;
}
