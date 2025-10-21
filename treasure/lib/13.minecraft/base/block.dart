import 'dart:ui';
import 'collider.dart';
import 'constant.dart';
import 'vector.dart';

/// 方块类型
/// 方块类型枚举（扩展常见方块类型）
enum BlockType {
  // 基础地形方块
  bedrock, // 基岩
  stone, // 石头
  dirt, // 泥土
  grass, // 草方块
  sand, // 沙子
  // 矿石
  coalOre, // 煤矿石
  ironOre, // 铁矿石
  goldOre, // 金矿石
  diamondOre, // 钻石矿石
  // 植物相关
  wood, // 树干
  leaf, // 树叶
  sapling, // 树苗
  // 液体
  water, // 水
  // 人造方块
  glass, // 玻璃
  planks, // 木板
  // 特殊类型
  air, // 空气
}

/// 方块类型属性扩展
extension BlockTypeProperties on BlockType {
  /// 方块颜色（含透明度）
  Color get color => {
    BlockType.bedrock: const Color(0xFF424242), // 深灰色
    BlockType.stone: const Color(0xFF9E9E9E), // 灰色
    BlockType.dirt: const Color(0xFF8D6E63), // 棕褐色
    BlockType.grass: const Color(0xFF4CAF50), // 绿色
    BlockType.sand: const Color(0xFFFFF3E0), // 浅黄色
    BlockType.coalOre: const Color(0xFF212121), // 近黑色（带煤点）
    BlockType.ironOre: const Color(0xFFB0BEC5), // 浅灰棕色（带铁矿点）
    BlockType.goldOre: const Color(0xFFFFD700), // 金黄色（带金矿点）
    BlockType.diamondOre: const Color(0xFF00BCD4), // 亮蓝色（带钻石点）
    BlockType.wood: const Color(0xFFFF9800), // 棕色（树干）
    BlockType.leaf: const Color(0xCC4CAF50), // 半透明绿色（树叶）
    BlockType.sapling: const Color(0xFF795548), // 深棕色（树苗）
    BlockType.water: const Color(0x882196F3), // 半透明蓝色（水）
    BlockType.glass: const Color(0xCCFFFFFF), // 半透明白色（玻璃）
    BlockType.planks: const Color(0xFF8D6E63), // 棕褐色（木板）
    BlockType.air: const Color(0x00000000), // 全透明（空气）
  }[this]!;

  /// 是否为固体（是否占据物理空间）
  bool get isSolid => this != BlockType.air;

  /// 是否透明（是否能透过看到后方）
  bool get isTransparent => [
    BlockType.leaf,
    BlockType.water,
    BlockType.glass,
    BlockType.air,
  ].contains(this);

  /// 是否为液体（特殊物理特性）
  bool get isLiquid => this == BlockType.water;

  /// 是否为矿石（可被开采获得资源）
  bool get isOre => [
    BlockType.coalOre,
    BlockType.ironOre,
    BlockType.goldOre,
    BlockType.diamondOre,
  ].contains(this);

  /// 硬度（影响开采难度，值越高越难开采）
  double get hardness => {
    BlockType.bedrock: double.infinity, // 不可破坏
    BlockType.stone: 1.5,
    BlockType.dirt: 0.5,
    BlockType.grass: 0.6,
    BlockType.sand: 0.5,
    BlockType.coalOre: 3.0,
    BlockType.ironOre: 3.0,
    BlockType.goldOre: 3.0,
    BlockType.diamondOre: 3.0,
    BlockType.wood: 2.0,
    BlockType.leaf: 0.2,
    BlockType.sapling: 0.1,
    BlockType.water: 100.0, // 无法直接破坏
    BlockType.glass: 0.3,
    BlockType.planks: 2.0,
    BlockType.air: 0.0,
  }[this]!;
}

/// 方块面数据
class BlockFace {
  static final faces = [
    BlockFace(
      [0, 1, 2, 3],
      const Vector3(0, 0, -1),
      Vector3(0, 0, -Constants.blockSizeHalf),
    ), // 前
    BlockFace(
      [4, 5, 6, 7],
      const Vector3(0, 0, 1),
      Vector3(0, 0, Constants.blockSizeHalf),
    ), // 后
    BlockFace(
      [1, 5, 6, 2],
      const Vector3(1, 0, 0),
      Vector3(Constants.blockSizeHalf, 0, 0),
    ), // 右
    BlockFace(
      [4, 0, 3, 7],
      const Vector3(-1, 0, 0),
      Vector3(-Constants.blockSizeHalf, 0, 0),
    ), // 左
    BlockFace(
      [3, 2, 6, 7],
      const Vector3(0, 1, 0),
      Vector3(0, Constants.blockSizeHalf, 0),
    ), // 上
    BlockFace(
      [0, 4, 5, 1],
      const Vector3(0, -1, 0),
      Vector3(0, -Constants.blockSizeHalf, 0),
    ), // 下
  ];

  final List<int> indices;
  final Vector3 normal;
  final Vector3 center;

  const BlockFace(this.indices, this.normal, this.center);
}

/// 游戏方块
class Block {
  final Vector3 position;
  final BlockType type;
  final BoxCollider collider;
  final List<Vector3> vertices;

  Block({required this.position, required this.type})
    : collider = BoxCollider(
        position: position,
        size: Vector3.all(Constants.blockSize),
      ),
      vertices = _calculateVertices(position);

  bool get penetrable => type == BlockType.air;

  static List<Vector3> _calculateVertices(Vector3 position) {
    final half = Constants.blockSizeHalf;
    final p = position;
    return [
      Vector3(p.x - half, p.y - half, p.z - half),
      Vector3(p.x + half, p.y - half, p.z - half),
      Vector3(p.x + half, p.y + half, p.z - half),
      Vector3(p.x - half, p.y + half, p.z - half),
      Vector3(p.x - half, p.y - half, p.z + half),
      Vector3(p.x + half, p.y - half, p.z + half),
      Vector3(p.x + half, p.y + half, p.z + half),
      Vector3(p.x - half, p.y + half, p.z + half),
    ];
  }

  /// 获取可见的面（剔除背向相机的面）
  List<BlockFace> getVisibleFaces(Vector3 cameraPosition) {
    if (penetrable) return [];

    return BlockFace.faces.where((face) {
      final faceCenter = _getFaceCenter(face.indices);
      final toCamera = (cameraPosition - faceCenter).normalized;
      return face.normal.dot(toCamera) > 0; // 面朝向相机
    }).toList();
  }

  Vector3 _getFaceCenter(List<int> indices) {
    Vector3 sum = Vector3.zero;
    for (final index in indices) {
      sum += vertices[index];
    }
    return sum / indices.length.toDouble();
  }
}
