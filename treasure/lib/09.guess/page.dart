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
            valueListenable: _manager.correctItems,
            builder: (_, correctItems, __) => Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center, // ③ 行内居中
              children: List.generate(
                correctItems.length,
                (index) => _buildOnePair(index), // ④ 抽出来
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 一对卡片：左侧猜物品 + 右侧标记
  Widget _buildOnePair(int index) {
    return Row(
      mainAxisSize: MainAxisSize.min, // ⑤ 关键：让这一行只包裹内容宽度
      children: [
        ValueListenableBuilder<List<String>>(
          valueListenable: _manager.guessItems,
          builder: (_, guessItems, __) =>
              _buildGuessCard(index, guessItems[index]),
        ),
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
    return ValueListenableBuilder<int>(
      valueListenable: _manager.selectedItem,
      builder: (_, selectedIndices, __) {
        final isSelected = index == selectedIndices;
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
    // 可点击的卡
    return GestureDetector(
      onTap: () => _manager.markSelect(index),
      child: Card(
        elevation: 4,
        color: Colors.amber[100],
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(emoji, style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
