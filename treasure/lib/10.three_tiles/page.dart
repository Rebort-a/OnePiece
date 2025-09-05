import 'package:flutter/material.dart';
import '../00.common/component/notifier_navigator.dart';
import 'base.dart';
import 'manager.dart';

/// 3TILES游戏页面
class ThreeTilesPage extends StatelessWidget {
  final ThreeTilesManager _manager = ThreeTilesManager();

  ThreeTilesPage({super.key});

  final ScrollController _scrollController = ScrollController();

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
      title: const Text('3tiles'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _manager.leavePage,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _manager.restartGame,
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _manager.showDifficultyDialog,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        NotifierNavigator(navigatorHandler: _manager.pageNavigator),

        // 计时和分数
        _buildDisplayRegion(),

        // 主要区域
        _buildScreenRegion(),

        // 道具区域
        _buildPropsArea(),

        // 选中的卡片区域
        _buildSelectedArea(),
      ],
    );
  }

  Widget _buildDisplayRegion() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _manager.elapsed,
            builder: (context, value, child) {
              return Text("时间: $value", style: const TextStyle(fontSize: 16));
            },
          ),
          ValueListenableBuilder<List<GameCard>>(
            valueListenable: _manager.cards,
            builder: (context, cards, child) {
              return Text(
                "剩余: ${cards.length}",
                style: const TextStyle(fontSize: 16),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScreenRegion() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SizedBox(
            width: mainRegionWidth,
            height: mainRegionHeight,
            child: Stack(
              children: [
                // 背景网格线，方便查看位置
                ...List.generate(100, (index) {
                  final x = index % 10;
                  final y = index ~/ 10;
                  return Positioned(
                    left: x * 60.toDouble(),
                    top: y * 60.toDouble(),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                    ),
                  );
                }),
                // 卡片
                ValueListenableBuilder<List<GameCard>>(
                  valueListenable: _manager.cards,
                  builder: (context, cards, child) {
                    // 按z轴排序，确保正确绘制顺序

                    return Stack(
                      children: cards
                          .map<Widget>((card) => _buildCard(card))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 卡片Widget
  Widget _buildCard(GameCard card) {
    return Positioned(
      left: card.position.x.toDouble(),
      top: card.position.y.toDouble(),
      child: GestureDetector(
        onTap: () => _manager.selectCard(card),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: card.enable
                ? Color(card.type.color)
                : Color(card.type.color & 0x00FFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: card.hint ? Colors.blue : Colors.grey,
              width: card.hint ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(card.type.emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }

  // 道具区域
  Widget _buildPropsArea() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<List<PropType>>(
        valueListenable: _manager.props,
        builder: (context, props, child) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _manager.props.value.length,
            itemBuilder: (context, index) {
              final prop = _manager.props.value[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => _manager.useProp(prop),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        prop.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 选中的卡片区域
  Widget _buildSelectedArea() {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: ValueListenableBuilder<List<GameCard>>(
        valueListenable: _manager.selectedCards,
        builder: (context, cards, child) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(card.type.color),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      card.type.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
