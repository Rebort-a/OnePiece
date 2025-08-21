import 'package:flutter/material.dart';

import '../00.common/network/network_room.dart';
import '../00.common/game/gamer.dart';
import '../00.common/game/step.dart';
import '../00.common/widget/notifier_navigator.dart';
import 'foundation_widget.dart';

import 'net_manager.dart';

class NetGomokuPage extends StatelessWidget {
  late final NetManager _manager;

  NetGomokuPage({
    super.key,
    required RoomInfo roomInfo,
    required String userName,
  }) {
    _manager = NetManager(roomInfo: roomInfo, userName: userName);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) {
      _manager.leavePage();
    },
    child: _buildPage(context),
  );

  Widget _buildPage(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('网络五子棋'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _manager.netTurnEngine.leavePage,
      ),
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder<GameStep>(
      valueListenable: _manager.netTurnEngine.gameStep,
      builder: (__, step, _) {
        return Center(
          child: Column(
            children: [
              NotifierNavigator(navigatorHandler: _manager.pageNavigator),
              ...(step == GameStep.action
                  ? [
                      _buildTurnIndicator(),
                      Expanded(child: FoundationalWidget(manager: _manager)),
                    ]
                  : _buildPrepare(step)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTurnIndicator() => ValueListenableBuilder(
    valueListenable: _manager.board.currentGamer,
    builder: (_, gamer, __) {
      String text = '';
      if (_manager.board.gameOver) {
        text = '${gamer == TurnGamerType.rear ? "黑方" : "白方"}获胜!';
      } else {
        text =
            '当前回合: ${gamer == _manager.netTurnEngine.playerType ? "你的" : "对方"} ${gamer == TurnGamerType.front ? "黑方" : "白方"}';
      }
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    },
  );

  List<Widget> _buildPrepare(GameStep step) {
    return [
      const SizedBox(height: 20),
      const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text(step.getExplaination()),
    ];
  }
}
