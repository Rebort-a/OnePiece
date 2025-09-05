import 'package:flutter/material.dart';
import '../00.common/component/notifier_navigator.dart';
import 'base.dart';
import 'manager.dart';

class ThreeTilesPage extends StatelessWidget {
  final ThreeTilesManager _manager = ThreeTilesManager();

  ThreeTilesPage({super.key});

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (_, __) => _manager.leavePage(),
    child: Scaffold(appBar: _appBar(), body: _body()),
  );

  AppBar _appBar() => AppBar(
    title: const Text('3tiles'),
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: _manager.leavePage,
    ),
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

  Widget _body() => Column(
    children: [
      NotifierNavigator(navigatorHandler: _manager.pageNavigator),
      _displayArea(),
      Expanded(child: _boardArea()),
      _propsArea(),
      _selectedArea(),
    ],
  );

  Widget _displayArea() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _manager.elapsed,
          builder: (_, value, __) =>
              Text('时间: $value 秒', style: const TextStyle(fontSize: 16)),
        ),
        ValueListenableBuilder<List<GameCard>>(
          valueListenable: _manager.cards,
          builder: (_, cards, __) =>
              Text('剩余: ${cards.length}', style: const TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );

  Widget _boardArea() => LayoutBuilder(
    builder: (_, cons) {
      double boardRealSize = cons.maxWidth - 32 < cons.maxHeight
          ? cons.maxWidth - 32
          : cons.maxHeight;

      double ratio = boardRealSize / boardVirtualSize;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRect(
          child: Stack(
            children: [
              ..._buildGrid(ratio),
              ValueListenableBuilder<List<GameCard>>(
                valueListenable: _manager.cards,
                builder: (_, cards, __) => Stack(
                  children: cards.map((c) => _buildCard(c, ratio)).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  List<Widget> _buildGrid(double radio) {
    final cardRealSize = cardVirtualSize * radio;
    return List.generate(cardRealSize.floor() * cardRealSize.floor(), (i) {
      final x = i % cardRealSize;
      final y = i ~/ cardRealSize;
      return Positioned(
        left: x * cardRealSize,
        top: y * cardRealSize,
        child: Container(
          width: cardRealSize,
          height: cardRealSize,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
          ),
        ),
      );
    });
  }

  Widget _buildCard(GameCard card, double radio) {
    final cardRealSize = cardVirtualSize * radio;

    return Positioned(
      left: card.position.x * radio,
      top: card.position.y * radio,
      child: GestureDetector(
        onTap: () => _manager.selectCard(card),
        child: Container(
          width: cardRealSize,
          height: cardRealSize,
          decoration: BoxDecoration(
            color: Color(
              card.type.color,
            ).withValues(alpha: card.enable ? 1 : 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: card.hint ? Colors.blue : Colors.grey,
              width: card.hint ? 3 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(1, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              card.type.emoji,
              style: TextStyle(fontSize: cardRealSize * 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _propsArea() => Container(
    height: 60,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: ValueListenableBuilder<List<PropType>>(
      valueListenable: _manager.props,
      builder: (_, props, __) => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: props.length,
        itemBuilder: (_, i) {
          final p = props[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => _manager.useProp(p),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _selectedArea() => Container(
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
      builder: (_, cards, __) => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        itemBuilder: (_, i) {
          final c = cards[i];
          return Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Color(c.type.color),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Center(
              child: Text(c.type.emoji, style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    ),
  );
}
