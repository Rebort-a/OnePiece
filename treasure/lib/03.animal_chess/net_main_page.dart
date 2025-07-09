import 'package:flutter/material.dart';

import '../00.common/game/gamer.dart';
import '../00.common/style/theme.dart';
import '../00.common/widget/chat_component.dart';
import '../00.common/game/step.dart';
import '../00.common/network/network_room.dart';

import '../00.common/widget/notifier_navigator.dart';

import 'net_chess_manager.dart';
import 'foundation_page.dart';

class NetAnimalChessPage extends StatelessWidget {
  late final NetAnimalChessManager _chessManager;

  final RoomInfo roomInfo;
  final String userName;

  NetAnimalChessPage({
    super.key,
    required this.roomInfo,
    required this.userName,
  }) {
    _chessManager = NetAnimalChessManager(
      roomInfo: roomInfo,
      userName: userName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, child: _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    return ValueListenableBuilder<TurnGameStep>(
      valueListenable: _chessManager.netTurnEngine.gameStep,
      builder: (__, step, _) {
        return Scaffold(appBar: _buildAppBar(step), body: _buildBody(step));
      },
    );
  }

  AppBar _buildAppBar(TurnGameStep step) {
    // 根据游戏步骤确定图标和点击事件
    IconData icon;
    VoidCallback? onPressed;

    if (step.index < TurnGameStep.action.index) {
      // 游戏准备阶段 - 返回按钮
      icon = Icons.arrow_back;
      onPressed = _chessManager.leavePage;
    } else if (step.index == TurnGameStep.action.index) {
      // 游戏进行阶段 - 投降按钮
      icon = Icons.flag; // 使用旗帜图标表示投降
      onPressed = _chessManager.surrender; // 假设存在surrender方法
    } else {
      // 游戏结束阶段 - 退出房间
      icon = Icons.exit_to_app;
      onPressed = _chessManager.exitRoom; // 假设存在exitRoom方法
    }

    return AppBar(
      leading: IconButton(icon: Icon(icon), onPressed: onPressed),
      title: const Text('斗兽棋'),
      centerTitle: true,
    );
  }

  Widget _buildBody(TurnGameStep step) {
    return Column(
      children: [
        // 弹出页面
        NotifierNavigator(navigatorHandler: _chessManager.pageNavigator),
        ...(step.index < TurnGameStep.action.index
            ? _buildPrepare(step)
            : [
                _buildTurnIndicator(),
                Expanded(
                  flex: 3,
                  child: BaseAnimalChessPage(
                    displayMap: _chessManager.displayMap,
                    onGridSelected: _chessManager.sendActionMessage,
                  ),
                ),
              ]),

        Expanded(
          flex: 1,
          child: MessageList(networkEngine: _chessManager.netTurnEngine),
        ),
        MessageInput(networkEngine: _chessManager.netTurnEngine),
      ],
    );
  }

  Widget _buildTurnIndicator() => ValueListenableBuilder(
    valueListenable: _chessManager.currentGamer,
    builder: (_, gamer, __) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: gamer == GamerType.front ? Colors.red : Colors.blue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${gamer == _chessManager.netTurnEngine.playerType ? "你的" : "对方"}回合',
        style: globalTheme.textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
    ),
  );

  List<Widget> _buildPrepare(TurnGameStep step) {
    return [
      const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text(step.getExplaination()),
    ];
  }
}
