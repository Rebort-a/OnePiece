import 'package:flutter/material.dart';

import '../00.common/component/notifier_navigator.dart';
import 'manager.dart';

class GuessPage extends StatelessWidget {
  final GuessManager _manager = GuessManager();

  GuessPage({super.key});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) {
      _manager.leavePage();
    },
    child: _buildPage(),
  );

  Widget _buildPage() {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Guess'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _manager.leavePage,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _manager.resetGame,
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: _manager.showSelector,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NotifierNavigator(navigatorHandler: _manager.pageNavigator),
        _buildDisplayArea(),
        _buildGuessArea(),
        _buildMarkPanel(),
      ],
    );
  }

  /// 1. 文本显示区
  Widget _buildDisplayArea() {
    return ValueListenableBuilder<String>(
      valueListenable: _manager.display,
      builder: (_, value, __) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 2. 猜物品区
  Widget _buildGuessArea() {
    return Expanded(
      // ① 占满剩余空间
      child: Center(
        // ② 让整个内容在主轴+交叉轴都居中
        child: SingleChildScrollView(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: _manager.guessItems,
            builder: (_, guessItems, __) => Wrap(
              spacing: 24,
              runSpacing: 32,
              alignment: WrapAlignment.center, // ③ 行内居中
              children: List.generate(
                guessItems.length,
                (index) => _buildOnePair(index, guessItems[index]), // ④ 抽出来
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 一对卡片：左侧猜物品 + 右侧标记
  Widget _buildOnePair(int index, String emoji) {
    return Row(
      mainAxisSize: MainAxisSize.min, // ⑤ 关键：让这一行只包裹内容宽度
      children: [
        _buildGuessCard(index, emoji),
        const SizedBox(width: 8),
        ValueListenableBuilder<List<String>>(
          valueListenable: _manager.markItems,
          builder: (_, markItems, __) =>
              _buildMarkCard(index, markItems[index]),
        ),
      ],
    );
  }

  Widget _buildGuessCard(int index, String emoji) {
    return ValueListenableBuilder<List<int>>(
      valueListenable: _manager.selectedIndices,
      builder: (_, selectedIndices, __) {
        final isSelected = selectedIndices.contains(index);
        return
        // 可点击的卡片（带动画）
        GestureDetector(
          onTap: () => _manager.guessSelect(index),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Card(
              key: ValueKey('$index-$emoji'),
              elevation: 4,
              color: isSelected ? Colors.blue[200] : Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 32, color: Colors.black),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarkCard(int index, String emoji) {
    return ValueListenableBuilder<int>(
      valueListenable: _manager.markItemIndex,
      builder: (_, markItemIndex, __) {
        final isSelected = index == markItemIndex;
        // 可点击的卡
        return GestureDetector(
          onTap: () => _manager.markSelect(index),
          child: Card(
            elevation: 4,
            color: isSelected ? Colors.yellow : Colors.amber[100],
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(emoji, style: TextStyle(fontSize: 32)),
            ),
          ),
        );
      },
    );
  }

  /// 底部滑出的标记面板
  Widget _buildMarkPanel() {
    return ValueListenableBuilder<int>(
      valueListenable: _manager.markItemIndex,
      builder: (_, markItemIndex, __) {
        if (markItemIndex == -1) {
          return const SizedBox.shrink();
        }

        // 使用LayoutBuilder获取父容器约束
        return LayoutBuilder(
          builder: (context, constraints) {
            // 计算面板宽度为可用宽度的3/4
            final panelWidth = constraints.maxWidth * 3 / 4;

            return Material(
              child: Container(
                // 设置固定宽度
                width: panelWidth,
                // 水平居中
                margin: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 1 / 8,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _manager.markSelect(-1),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 24,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<List<String>>(
                      valueListenable: _manager.guessItems,
                      builder: (_, items, __) {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [_buildMarkChip("❓"), _buildMarkChip("✔️")],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 单个标记 Chip —— FilterChip 版
  Widget _buildMarkChip(String emoji) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: _manager.markItems,
      builder: (_, markItems, __) {
        final isSelected = markItems[_manager.markItemIndex.value] == emoji;
        return FilterChip(
          label: Text(emoji, style: const TextStyle(fontSize: 24)),
          selected: isSelected,
          onSelected: (_) {
            _manager.changeMark(emoji); // 更新标记
          },
        );
      },
    );
  }
}
