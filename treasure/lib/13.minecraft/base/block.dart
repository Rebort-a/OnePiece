import 'dart:ui';
import 'collider.dart';
import 'constant.dart';
import 'face.dart';
import 'vector.dart';

/// 方块类型
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

  bool get isPenetrate =>
      [BlockType.air, BlockType.water, BlockType.leaf].contains(this);

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
}

/// 方块面数据
class BlockFace {
  final BlockType type;
  final Vector3Int center;
  final Vector3Int normal;
  final List<Vector3Int> vertices;

  const BlockFace({
    required this.type,
    required this.center,
    required this.normal,
    required this.vertices,
  });
}

/// 方块
class Block {
  final Vector3Int position;
  final BlockType type;
  final FixedBoxCollider collider;
  final List<Vector3Int> _vertices;
  late final List<BlockFace> _faces;

  Vector3? _lastCameraPosition;
  List<BlockFace>? _cachedVisibleFaces;

  Block({required this.position, required this.type})
    : collider = FixedBoxCollider(
        position: position,
        halfSize: Vector3Int.all(Constants.blockSizeHalf),
      ),
      _vertices = _getVertices(position) {
    _faces = _getFaces(position, type, _vertices);
  }

  static List<Vector3Int> _getVertices(Vector3Int position) {
    final half = Constants.blockSizeHalf;
    final p = position;
    return [
      Vector3Int(p.x - half, p.y - half, p.z - half),
      Vector3Int(p.x + half, p.y - half, p.z - half),
      Vector3Int(p.x + half, p.y + half, p.z - half),
      Vector3Int(p.x - half, p.y + half, p.z - half),
      Vector3Int(p.x - half, p.y - half, p.z + half),
      Vector3Int(p.x + half, p.y - half, p.z + half),
      Vector3Int(p.x + half, p.y + half, p.z + half),
      Vector3Int(p.x - half, p.y + half, p.z + half),
    ];
  }

  // 初始化方块的所有面（计算每个面的中心点）
  static List<BlockFace> _getFaces(
    Vector3Int position,
    BlockType type,
    List<Vector3Int> vertices,
  ) {
    final halfSize = Constants.blockSizeHalf;

    return FaceIdentify.hexahedron.map((face) {
      final faceCenter = position + face.normal * halfSize;
      final faceVertices = face.indices
          .map((index) => vertices[index])
          .toList();

      return BlockFace(
        type: type,
        center: faceCenter,
        normal: face.normal,
        vertices: faceVertices,
      );
    }).toList();
  }

  /// 获取可见的面（剔除背向相机的面）
  List<BlockFace> getVisibleFaces(Vector3 cameraPosition) {
    if (_lastCameraPosition == cameraPosition && _cachedVisibleFaces != null) {
      return _cachedVisibleFaces!;
    }

    _lastCameraPosition = cameraPosition;

    // 透明方块不进行背面剔除，返回所有面
    if (type.isTransparent) {
      _cachedVisibleFaces = _faces;
    } else {
      _cachedVisibleFaces = _faces.where((face) {
        // 使用预计算的面中心点和法向量进行可见性判断
        final toCamera = (cameraPosition - face.center.toVector3()).normalized;
        return face.normal.dotWithVector3(toCamera) > 0; // 面朝向相机则可见
      }).toList();
    }

    return _cachedVisibleFaces!;
  }

  List<Vector3Int> get vertices => _vertices;
  List<BlockFace> get faces => _faces;
}
