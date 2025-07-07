import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../00.common/engine/net_turn_engine.dart';
import '../../00.common/game/step.dart';
import '../../00.common/network/network_message.dart';
import '../../00.common/network/network_room.dart';

import '../middleware/base_combat_manager.dart';
import '../middleware/elemental.dart';
import '../foundation/energy.dart';

import '../middleware/common.dart';
import '../foundation/skill.dart';

import '../upper/cast_page.dart';
import '../upper/status_page.dart';

class NetCombatManager extends BaseCombatManager {
  late final NetTurnEngine netTurnEngine;

  NetCombatManager({required String userName, required RoomInfo roomInfo}) {
    // 使用局部函数初始化NetTurnEngine
    netTurnEngine = NetTurnEngine(
      userName: userName,
      roomInfo: roomInfo,
      pageNavigator: pageNavigator,
      searchHandler: _searchHandler,
      resourceHandler: _resourceHandler,
      actionHandler: _actionHandler,
    );
  }

  // 定义搜索处理局部函数（空实现）
  void _searchHandler() {}

  // 定义资源处理局部函数
  void _resourceHandler(TurnGameStep step, NetworkMessage message) {
    if (step == TurnGameStep.frontConfig) {
      player = Elemental.fromSocket(jsonDecode(message.content));
    } else if (step == TurnGameStep.frontWait) {
      enemy = Elemental.fromSocket(jsonDecode(message.content));
      initCombat(netTurnEngine.playerType);
    } else if (step == TurnGameStep.connected) {
      netTurnEngine.enemyIdentify = message.id;
      enemy = Elemental.fromSocket(jsonDecode(message.content));
    } else if (step == TurnGameStep.rearConfig) {
      enemy = Elemental.fromSocket(jsonDecode(message.content));
    } else if (step == TurnGameStep.rearConfig) {
      player = Elemental.fromSocket(jsonDecode(message.content));
      initCombat(netTurnEngine.playerType);
    }
  }

  // 定义动作处理局部函数
  void _actionHandler(bool isSelf, NetworkMessage message) {
    final action = GameAction.fromJson(jsonDecode(message.content));
    final actionType = _getActionType(action.actionIndex);

    if (isSelf && (netTurnEngine.playerType != currentGamer.value)) {
      return addCombatInfo('\n服务器：不是你的回合\n');
    }

    addCombatInfo(
      '${message.source} 选择了 ${BaseCombatManager.conationNames[actionType]}',
    );

    final actionHandlers = {
      ConationType.attack: () => handleAttack(isSelf),
      ConationType.escape: () => handleEscape(isSelf),
      ConationType.parry: () => handleSkill(isSelf, action),
      ConationType.skill: () => handleSkill(isSelf, action),
    };

    actionHandlers[actionType]?.call();
  }

  void navigateToCastPage() {
    pageNavigator.value = (context) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              maintainState: true,
              builder: (_) => const CastPage(totalPoints: 30),
            ),
          )
          .then((configs) {
            if (configs != null) {
              _sendRoleConfig(configs);
            }
          });
    };
  }

  void _sendRoleConfig(Map<EnergyType, EnergyConfig> configs) {
    netTurnEngine.networkEngine.sendNetworkMessage(
      MessageType.resource,
      jsonEncode(
        Elemental.configsToJson(
          netTurnEngine.networkEngine.userName,
          configs,
          Random().nextInt(EnergyType.values.length),
        ),
      ),
    );
  }

  void navigateToStatePage() {
    pageNavigator.value = (BuildContext context) {
      Navigator.of(context).push(
        MaterialPageRoute(
          maintainState: true,
          builder: (_) => StatusPage(elemental: enemy),
        ),
      );
    };
  }

  @override
  void handlePlayerAction(ConationType action) {
    if (combatResult != ResultType.continued) {
      leavePage();
    } else {
      switch (action) {
        case ConationType.attack:
          _sendActionMessage(ConationType.attack.index, enemy.current);
          break;
        case ConationType.parry:
          handlePlayerSkillTarget(-1);
          break;
        case ConationType.skill:
          showSkillSelection();
          break;
        case ConationType.escape:
          handleConationEscape();
          break;
      }
    }
  }

  void handleConationEscape() {
    _sendActionMessage(ConationType.escape.index, player.current);
    updateGameStepAfterAction(true, 2); // 直接处理，不需要服务器返回，防止服务器断开时无法退出
  }

  @override
  void handlePlayerSkillTarget(int skillIndex) {
    final actionIndex = ConationType.skill.index + skillIndex;
    final skills = player.getAppointSkills(player.current);
    final skill = skillIndex == -1
        ? SkillCollection.baseParry
        : skills[skillIndex];

    bool isSelf = getSkillCategory(skill);
    bool isFront = getSkillRange(skill);

    final elemental = isSelf ? player : enemy;

    if (isFront) {
      _sendActionMessage(actionIndex, elemental.current);
    } else {
      showEnergySelection(elemental, (i) => _sendActionMessage(actionIndex, i));
    }
  }

  void _sendActionMessage(int actionIndex, int targetIndex) {
    if ((netTurnEngine.playerType == currentGamer.value) ||
        (actionIndex == ConationType.escape.index)) {
      netTurnEngine.networkEngine.sendNetworkMessage(
        MessageType.action,
        jsonEncode(
          GameAction(actionIndex: actionIndex, targetIndex: targetIndex),
        ),
      );
    } else {
      addCombatInfo('\n不是你的回合!\n');
    }
  }

  ConationType _getActionType(int index) {
    return index < ConationType.values.length
        ? ConationType.values[index]
        : ConationType.skill;
  }

  @override
  void leavePage() {
    netTurnEngine.networkEngine.leavePage();
  }
}
