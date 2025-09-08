import 'package:flutter/material.dart';
import 'package:treasure/04.elemental_battle/middle/foundation_combat_widget.dart';

import '../../00.common/game/step.dart';
import '../../00.common/network/network_room.dart';
import '../../00.common/component/chat_component.dart';
import '../../00.common/component/notifier_navigator.dart';
import 'net_combat_manager.dart';

class NetCombatPage extends StatelessWidget {
  late final NetCombatManager _manager;

  NetCombatPage({
    super.key,
    required RoomInfo roomInfo,
    required String userName,
  }) {
    _manager = NetCombatManager(roomInfo: roomInfo, userName: userName);
  }

  @override
  Widget build(BuildContext context) =>
      PopScope(canPop: false, child: _buildPage(context));

  Widget _buildPage(BuildContext context) {
    return ValueListenableBuilder<GameStep>(
      valueListenable: _manager.netTurnEngine.gameStep,
      builder: (__, step, _) {
        if (step.index == GameStep.action.index) {
          return _buildGame(step);
        } else {
          return _buildPrepare(step);
        }
      },
    );
  }

  Widget _buildGame(GameStep step) {
    return Scaffold(
      body: Column(
        children: [
          // 弹出页面
          NotifierNavigator(navigatorHandler: _manager.pageNavigator),

          ...FoundationalCombatWidget(combatManager: _manager).buildPage(),

          Expanded(child: MessageList(networkEngine: _manager.netTurnEngine)),
          MessageInput(networkEngine: _manager.netTurnEngine),
        ],
      ),
    );
  }

  Widget _buildPrepare(GameStep step) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _manager.leavePage,
          icon: Icon(Icons.arrow_back),
        ),
        title: const Text('准备中'),
        centerTitle: true,
      ),

      body: Center(
        child: Column(
          children: [
            NotifierNavigator(navigatorHandler: _manager.pageNavigator),
            const SizedBox(height: 20),
            if (step == GameStep.disconnect || step == GameStep.connected)
              const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(step.getExplaination()),
            const SizedBox(height: 20),
            if (step == GameStep.frontConfig || step == GameStep.rearConfig)
              ElevatedButton(
                onPressed: () => _manager.navigateToCastPage(),
                child: const Text('配置角色'),
              ),
            const SizedBox(height: 20),
            if (step == GameStep.rearConfig)
              ElevatedButton(
                onPressed: () => _manager.navigateToStatePage(),
                child: const Text('查看对手信息'),
              ),
          ],
        ),
      ),
    );
  }
}
