import 'dart:math';

import 'package:flutter/material.dart';

import '../../00.common/widget/notifier_navigator.dart';
import '../../00.common/widget/scale_button.dart';
import '../../00.common/image/image_manager.dart';
import '../foundation/energy.dart';

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
        appBar: _buildAppBar(),
        body: OrientationBuilder(
          builder: (context, orientation) {
            // 根据屏幕方向选择布局
            return orientation == Orientation.portrait
                ? _buildPortraitLayout(context)
                : _buildLandscapeLayout(context);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    toolbarHeight: 32.0,
    title: ValueListenableBuilder<int>(
      valueListenable: _manager.floorNum,
      builder: (context, value, _) => Text(value > 0 ? '地下$value层' : '主城'),
    ),
    centerTitle: true,
  );

  // 竖屏布局
  Widget _buildPortraitLayout(BuildContext context) => Column(
    children: [
      NotifierNavigator(navigatorHandler: _manager.pageNavigator),

      // 地图区域
      Flexible(
        child: Column(
          children: [
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
      _buildDirectionButtonRegion(),

      SizedBox(height: 64),
    ],
  );

  // 横屏布局
  Widget _buildLandscapeLayout(BuildContext context) => Row(
    children: [
      NotifierNavigator(navigatorHandler: _manager.pageNavigator),
      Expanded(
        flex: 3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 行为按钮区域
            Expanded(
              flex: 6,
              child: _buildActionButtonRegion(context, Axis.vertical),
            ),
            Spacer(flex: 1),
            //信息区域
            Expanded(flex: 4, child: _buildInfoRegion(Axis.vertical)),
          ],
        ),
      ),

      // 地图区域
      Expanded(flex: 5, child: _buildMapRegion()),
      // 方向按钮区域
      Expanded(flex: 3, child: _buildDirectionButtonRegion()),
    ],
  );

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
              return const Text('地图数据为空');
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                //取像素整数
                final size = _calculateBoardSize(constraints, _manager.mapSize);

                return SizedBox(
                  width: size,
                  height: size,
                  child: GridView.builder(
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
