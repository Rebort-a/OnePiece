import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import '../00.common/style/theme.dart';
import '../00.common/widget/notifier_navigator.dart';

import 'local_chess_manager.dart';
import 'foundation_page.dart';

class LoaclAnimalChessPage extends StatelessWidget {
  final LoaclAnimalChessManager _chessManager = LoaclAnimalChessManager();

  LoaclAnimalChessPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: _buildAppBar(), body: _buildBody());

  AppBar _buildAppBar() => AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: _chessManager.leaveChess,
    ),
    title: const Text('斗兽棋'),
    centerTitle: true,
  );

  Widget _buildBody() => Column(
    children: [
      NotifierNavigator(navigatorHandler: _chessManager.pageNavigator),
      _buildTurnIndicator(),
      Expanded(
        child: BasePage(
          displayMap: _chessManager.displayMap,
          boardSize: _chessManager.boardSize,
          onGridSelected: _chessManager.selectGrid,
        ),
      ),
    ],
  );

  Widget _buildTurnIndicator() => ValueListenableBuilder(
    valueListenable: _chessManager.currentGamer,
    builder: (_, gamer, __) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: gamer == GamerType.front ? Colors.red : Colors.blue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${gamer == GamerType.front ? "红" : "蓝"}方回合',
        style: globalTheme.textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
    ),
  );
}
