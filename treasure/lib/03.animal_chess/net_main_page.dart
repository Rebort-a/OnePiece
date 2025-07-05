import 'package:flutter/material.dart';

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

  Widget _buildBody() {
    return ValueListenableBuilder<TurnGameStep>(
      valueListenable: _chessManager.gameStep,
      builder: (__, step, _) {
        return Column(
          children: [
            // 弹出页面
            NotifierNavigator(navigatorHandler: _chessManager.pageNavigator),
            ...(step.index < TurnGameStep.action.index
                ? _buildPrepare(step)
                : [
                    Expanded(
                      flex: 3,
                      child: BasePage(
                        displayMap: _chessManager.displayMap,
                        currentGamer: _chessManager.currentGamer,
                        onGridSelected: _chessManager.sendActionMessage,
                        boardSize: _chessManager.boardSize,
                      ),
                    ),
                  ]),

            Expanded(
              flex: 1,
              child: MessageList(networkEngine: _chessManager.networkEngine),
            ),
            MessageInput(networkEngine: _chessManager.networkEngine),
          ],
        );
      },
    );
  }

  List<Widget> _buildPrepare(TurnGameStep step) {
    String statusMessage = _getStatusMessage(step);

    return [
      const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text(statusMessage),
    ];
  }

  String _getStatusMessage(TurnGameStep gameStep) {
    switch (gameStep) {
      case TurnGameStep.disconnect:
        return "等待连接";
      case TurnGameStep.connected:
        return "已连接，等待对手加入...";
      case TurnGameStep.frontConfig:
        return "请配置";
      case TurnGameStep.rearWait:
        return "等待先手配置";
      case TurnGameStep.frontWait:
        return "等待后手配置";
      case TurnGameStep.rearConfig:
        return "请配置或查看对方配置";
      default:
        return "游戏结束";
    }
  }
}
