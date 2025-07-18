import 'dart:math';

import 'package:flutter/material.dart';

import '../../00.common/widget/floor_banner.dart';
import '../../00.common/widget/notifier_navigator.dart';
import '../../00.common/widget/scale_button.dart';
import '../foundation/energy.dart';
import '../../00.common/image/image_manager.dart';

import 'maze_manager.dart';

class MazePage extends StatelessWidget {
  final MazeManager _manager = MazeManager();

  MazePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        _manager.leavePage();
      },
      child: Scaffold(
        body: Stack(
          children: [
            OrientationBuilder(
              builder: (context, orientation) {
                return orientation == Orientation.portrait
                    ? _buildPortraitLayout(context)
                    : _buildLandscapeLayout(context);
              },
            ),

            // 悬浮层数横幅
            Positioned(top: 0, left: 50, right: 50, child: _buildBanner()),

            // 退出按钮
            Positioned(
              top: 0,
              left: 0,
              child: _buildIconButton(
                icon: Icons.arrow_back,
                onPressed: _manager.leavePage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10), // 圆角半径改为10
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: 25, // 水波纹效果半径
      ),
    );
  }

  Widget _buildBanner() {
    return ValueListenableBuilder<int>(
      valueListenable: _manager.floorNum,
      builder: (context, value, child) {
        return FloorBanner(text: value > 0 ? '地下$value层' : '主城');
      },
    );
  }

  // 竖屏布局
  Widget _buildPortraitLayout(BuildContext context) => Column(
    children: [
      // 弹出页面
      NotifierNavigator(navigatorHandler: _manager.pageNavigator),

      Flexible(
        child: Column(
          children: [
            // 地图区域
            Expanded(flex: 8, child: _buildMapRegion()),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // 信息区域
                  _buildInfoRegion(Axis.horizontal),
                  // 行为按钮区域
                  _buildActionButtonRegion(context, Axis.horizontal),
                ],
              ),
            ),
          ],
        ),
      ),
      // 方向按钮区域
      _buildDirectionButtonRegion(),
      // 底部空白区域
      _buildBlankRegion(),
    ],
  );

  // 横屏布局
  Widget _buildLandscapeLayout(BuildContext context) => Row(
    children: [
      // 弹出页面
      NotifierNavigator(navigatorHandler: _manager.pageNavigator),
      Expanded(
        flex: 3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 行为按钮区域
            _buildActionButtonRegion(context, Axis.vertical),

            //信息区域
            _buildInfoRegion(Axis.vertical),
          ],
        ),
      ),
      // 地图区域
      Expanded(flex: 5, child: _buildMapRegion()),
      // 方向按钮区域
      Expanded(flex: 3, child: _buildDirectionButtonRegion()),
    ],
  );

  Widget _buildBlankRegion() {
    return const SizedBox(height: 64);
  }

  Widget _buildMapRegion() => AspectRatio(
    aspectRatio: 1.0, // 宽高比为1:1（正方形）
    child: Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueGrey,
          border: Border.all(color: Colors.grey, width: 8),
        ),
        child: ValueListenableBuilder(
          valueListenable: _manager.displayMap,
          builder: (context, map, _) {
            if (map.isEmpty) {
              return const Center(child: Text('地图数据为空'));
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                //取像素整数
                final size = _calculateBoardSize(constraints, _manager.mapSize);

                return SizedBox(
                  width: size,
                  height: size,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _manager.mapSize, // 列数
                      childAspectRatio: 1, // 单元格正方形
                      mainAxisSpacing: 0, // 移除网格间距
                      crossAxisSpacing: 0,
                    ),
                    itemCount: _manager.mapSize * _manager.mapSize, // 总单元格数
                    itemBuilder: (context, index) {
                      return ValueListenableBuilder(
                        valueListenable: map[index],
                        builder: (context, value, child) {
                          return ImageManager().getImage(
                            value.id,
                            value.foreIndex,
                            value.backIndex,
                            value.fogFlag,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
  );

  double _calculateBoardSize(BoxConstraints constraints, int cellCount) {
    final double maxSize = min(constraints.maxWidth, constraints.maxHeight);
    return (maxSize ~/ cellCount) * cellCount.toDouble();
  }

  Widget _buildInfoRegion(Axis direction) {
    final infoItems = [
      _InfoItem(label: "🌈", value: _manager.player.preview.typeString),
      _InfoItem(
        label: attributeNames[AttributeType.hp.index],
        value: _manager.player.preview.health,
      ),
      _InfoItem(
        label: attributeNames[AttributeType.atk.index],
        value: _manager.player.preview.attack,
      ),
      _InfoItem(
        label: attributeNames[AttributeType.def.index],
        value: _manager.player.preview.defence,
      ),
    ];

    final children = direction == Axis.horizontal
        ? infoItems
        : [const Spacer(flex: 1), ...infoItems];

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: direction == Axis.horizontal
          ? Row(children: children)
          : Column(children: children),
    );
  }

  Widget _buildActionButtonRegion(BuildContext context, Axis direction) {
    final buttons = [
      _ActionButton(
        text: "背包",
        onPressed: () => _manager.navigateToPackagePage(context),
      ),
      _ActionButton(
        text: "技能",
        onPressed: () => _manager.navigateToSkillsPage(context),
      ),
      _ActionButton(
        text: "状态",
        onPressed: () => _manager.navigateToStatusPage(context),
      ),
      _ActionButton(text: "切换", onPressed: _manager.switchPlayerNext),
    ];

    return direction == Axis.horizontal
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buttons,
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buttons,
          );
  }

  Widget _buildDirectionButtonRegion() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(height: 16),
      _DirectionButton(
        onTap: _manager.movePlayerUp,
        icon: Icons.keyboard_arrow_up,
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DirectionButton(
            onTap: _manager.movePlayerLeft,
            icon: Icons.keyboard_arrow_left,
          ),
          const SizedBox(width: 16 * 4),
          _DirectionButton(
            onTap: _manager.movePlayerRight,
            icon: Icons.keyboard_arrow_right,
          ),
        ],
      ),
      const SizedBox(height: 16),
      _DirectionButton(
        onTap: _manager.movePlayerDown,
        icon: Icons.keyboard_arrow_down,
      ),
    ],
  );
}

class _InfoItem extends StatelessWidget {
  final String label;
  final ValueNotifier<dynamic> value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: ValueListenableBuilder(
        valueListenable: value,
        builder: (_, val, __) =>
            Text("$label: $val", textAlign: TextAlign.center),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _ActionButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }
}

class _DirectionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;

  const _DirectionButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      size: const Size.square(48),
      onTap: onTap,
      // icon: Icon(icon, size: _LayoutConstants.buttonSize),
    );
  }
}
