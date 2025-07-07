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
    // 根据游戏步骤确定图标和点击事件
    IconData icon;
    VoidCallback? onPressed;
    String title;

    if (step.index < TurnGameStep.action.index) {
      // 游戏准备阶段 - 返回按钮
      icon = Icons.arrow_back;
      onPressed = _combatManager.leavePage;
      title = "准备";
    } else if (step.index == TurnGameStep.action.index) {
      // 游戏进行阶段 - 投降按钮
      icon = Icons.flag; // 使用旗帜图标表示投降
      onPressed = _combatManager.handleConationEscape; // 假设存在surrender方法
      title = "战斗";
    } else {
      // 游戏结束阶段 - 退出房间
      icon = Icons.exit_to_app;
      onPressed = _combatManager.leavePage; // 假设存在exitRoom方法
      title = "结算";
    }

    return AppBar(
      leading: IconButton(icon: Icon(icon), onPressed: onPressed),
      title: Text(title),
      centerTitle: true,
    );
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
    String statusMessage = _getStatusMessage(step);

    return [
      if (step == TurnGameStep.disconnect || step == TurnGameStep.connected)
        const CircularProgressIndicator(),
      const SizedBox(height: 20),
      Text(statusMessage),
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
        return "战斗结束";
    }
  }
}
