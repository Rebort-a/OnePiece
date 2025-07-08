import 'package:flutter/material.dart';
import 'package:treasure/04.elemental_battle/middleware/base_combat_page.dart';

import '../../00.common/game/step.dart';
import '../../00.common/network/network_room.dart';
import '../../00.common/widget/chat_component.dart';
import '../../00.common/widget/notifier_navigator.dart';
import 'net_combat_manager.dart';

class NetCombatPage extends StatelessWidget {
  late final NetCombatManager _combatManager;

  NetCombatPage({
    super.key,
    required RoomInfo roomInfo,
    required String userName,
  }) {
    _combatManager = NetCombatManager(roomInfo: roomInfo, userName: userName);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, child: _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    return ValueListenableBuilder<TurnGameStep>(
      valueListenable: _combatManager.netTurnEngine.gameStep,
      builder: (__, step, _) {
        return Scaffold(appBar: _buildAppBar(step), body: _buildBody(step));
      },
    );
  }

  AppBar _buildAppBar(TurnGameStep step) {
    if (step.index <= TurnGameStep.connected.index) {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _combatManager.leavePage,
        ),
        title: Text("等待"),
        centerTitle: true,
      );
    } else if (step.index == TurnGameStep.action.index) {
      return AppBar(
        title: Text("战斗"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      );
    } else {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.exit_to_app),
          onPressed: _combatManager.exitRoom,
        ),
        title: Text("结算"),
        centerTitle: true,
      );
    }
  }

  Widget _buildBody(TurnGameStep step) {
    return Column(
      children: [
        // 弹出页面
        NotifierNavigator(navigatorHandler: _combatManager.pageNavigator),
        ...(step.index >= TurnGameStep.action.index
            ? BaseCombatPage(combatManager: _combatManager).buildPage()
            : _buildPrepare(step)),

        Expanded(
          child: MessageList(
            networkEngine: _combatManager.netTurnEngine.networkEngine,
          ),
        ),
        MessageInput(networkEngine: _combatManager.netTurnEngine.networkEngine),
      ],
    );
  }

  List<Widget> _buildPrepare(TurnGameStep step) {
    return [
      if (step == TurnGameStep.disconnect || step == TurnGameStep.connected)
        const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text(step.getExplaination()),
      const SizedBox(height: 20),
      if (step == TurnGameStep.frontConfig || step == TurnGameStep.rearConfig)
        ElevatedButton(
          onPressed: () => _combatManager.navigateToCastPage(),
          child: const Text('配置角色'),
        ),
      const SizedBox(height: 20),
      if (step == TurnGameStep.rearConfig)
        ElevatedButton(
          onPressed: () => _combatManager.navigateToStatePage(),
          child: const Text('查看对手信息'),
        ),
    ];
  }
}
