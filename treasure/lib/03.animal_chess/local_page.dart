import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import '../00.common/style/theme.dart';
import '../00.common/widget/notifier_navigator.dart';

import 'local_manager.dart';
import 'foundation_widget.dart';

class LoaclAnimalChessPage extends StatelessWidget {
  final LoaclManager _manager = LoaclManager();

  LoaclAnimalChessPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: _buildAppBar(), body: _buildBody());

  AppBar _buildAppBar() => AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: _manager.leavePage,
    ),
    title: const Text('斗兽棋'),
    centerTitle: true,
    // 添加设置按钮
    actions: [
      IconButton(
        icon: const Icon(Icons.tune),
        // icon: const Icon(Icons.multitrack_audio_sharp),
        // icon: const Icon(Icons.equalizer),
        onPressed: _manager.showBoardSizeSelector,
      ),
    ],
  );

  Widget _buildBody() => Column(
    children: [
      NotifierNavigator(navigatorHandler: _manager.pageNavigator),
      _buildTurnIndicator(),
      Expanded(
        child: FoundationalWidget(
          displayMap: _manager.displayMap,
          onGridSelected: _manager.selectGrid,
        ),
      ),
    ],
  );

  Widget _buildTurnIndicator() => ValueListenableBuilder(
    valueListenable: _manager.currentGamer,
    builder: (_, gamer, __) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: gamer == TurnGamerType.front ? Colors.red : Colors.blue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${gamer == TurnGamerType.front ? "红" : "蓝"}方回合',
        style: globalTheme.textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
    ),
  );
}
