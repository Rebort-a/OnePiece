import 'package:flutter/material.dart';
import 'package:treasure/04.elemental_battle/middleware/foundation_combat_widget.dart';

import '../../00.common/game/step.dart';
import '../../00.common/network/network_room.dart';
import '../../00.common/widget/chat_component.dart';
import '../../00.common/widget/notifier_navigator.dart';
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
        return Scaffold(body: _buildBody(step));
      },
    );
  }

  Widget _buildBody(GameStep step) {
    return Column(
      children: [
        // 弹出页面
        NotifierNavigator(navigatorHandler: _manager.pageNavigator),
        ...(step.index >= GameStep.action.index
            ? FoundationalCombatWidget(combatManager: _manager).buildPage()
            : _buildPrepare(step)),

        Expanded(child: MessageList(networkEngine: _manager.netTurnEngine)),
        MessageInput(networkEngine: _manager.netTurnEngine),
      ],
    );
  }

  List<Widget> _buildPrepare(GameStep step) {
    return [
      // 退出按钮
      Positioned(
        top: 0,
        left: 0,
        child: _buildIconButton(
          icon: Icons.arrow_back,
          onPressed: _manager.leavePage,
        ),
      ),
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
    ];
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10), // 圆角半径改为10
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: 25, // 水波纹效果半径
      ),
    );
  }
}
