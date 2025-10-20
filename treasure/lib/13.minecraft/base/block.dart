import 'dart:ui';
import 'collider.dart';
import 'constant.dart';
import 'vector.dart';

/// 方块类型
enum BlockType { grass, dirt, stone, wood, leaf, glass, air }

extension BlockTypeProperties on BlockType {
  Color get color => {
    BlockType.grass: const Color(0xFF4CAF50),
    BlockType.dirt: const Color(0xFF8D6E63),
    BlockType.stone: const Color(0xFF9E9E9E),
    BlockType.wood: const Color(0xFFFF9800),
    BlockType.leaf: const Color(0x884CAF50),
    BlockType.glass: const Color(0x88FFFFFF),
    BlockType.air: const Color(0x00000000),
  }[this]!;

  bool get isSolid => this != BlockType.air;
  bool get isTransparent => this == BlockType.glass || this == BlockType.leaf;
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
    if (!type.isSolid) return [];

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
