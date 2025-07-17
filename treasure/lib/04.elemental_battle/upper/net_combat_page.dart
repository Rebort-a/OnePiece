import 'package:flutter/material.dart';
import 'package:treasure/04.elemental_battle/middleware/foundation_combat_widget.dart';

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
    return ValueListenableBuilder<GameStep>(
      valueListenable: _combatManager.netTurnEngine.gameStep,
      builder: (__, step, _) {
        return Scaffold(appBar: _buildAppBar(step), body: _buildBody(step));
      },
    );
  }

  AppBar _buildAppBar(GameStep step) {
    if (step.index <= GameStep.connected.index) {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _combatManager.leavePage,
        ),
        title: Text("等待"),
        centerTitle: true,
      );
    } else if (step.index == GameStep.action.index) {
      return AppBar(
        title: Text("战斗"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      );
    } else {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.exit_to_app),
          onPressed: _combatManager.leavePage,
        ),
        title: Text("结算"),
        centerTitle: true,
      );
    }
  }

  Widget _buildBody(GameStep step) {
    return Column(
      children: [
        // 弹出页面
        NotifierNavigator(navigatorHandler: _combatManager.pageNavigator),
        ...(step.index >= GameStep.action.index
            ? FoundationalCombatWidget(
                combatManager: _combatManager,
              ).buildPage()
            : _buildPrepare(step)),

        Expanded(
          child: MessageList(networkEngine: _combatManager.netTurnEngine),
        ),
        MessageInput(networkEngine: _combatManager.netTurnEngine),
      ],
    );
  }

  List<Widget> _buildPrepare(GameStep step) {
    return [
      const SizedBox(height: 20),
      if (step == GameStep.disconnect || step == GameStep.connected)
        const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text(step.getExplaination()),
      const SizedBox(height: 20),
      if (step == GameStep.frontConfig || step == GameStep.rearConfig)
        ElevatedButton(
          onPressed: () => _combatManager.navigateToCastPage(),
          child: const Text('配置角色'),
        ),
      const SizedBox(height: 20),
      if (step == GameStep.rearConfig)
        ElevatedButton(
          onPressed: () => _combatManager.navigateToStatePage(),
          child: const Text('查看对手信息'),
        ),
    ];
  }
}
