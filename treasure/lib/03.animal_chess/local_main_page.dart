import 'package:flutter/material.dart';

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
      Expanded(
        child: BasePage(
          displayMap: _chessManager.displayMap,
          currentGamer: _chessManager.currentGamer,
          onGridSelected: _chessManager.selectGrid,
          boardSize: _chessManager.boardSize,
        ),
      ),
    ],
  );
}
