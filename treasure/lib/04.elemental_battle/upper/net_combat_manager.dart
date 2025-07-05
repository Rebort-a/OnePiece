import 'dart:convert';

import 'dart:math';

import 'package:flutter/material.dart';

import '../../00.common/game/step.dart';
import '../../00.common/utils/template_dialog.dart';
import '../../00.common/engine/network_engine.dart';
import '../../00.common/utils/custom_notifier.dart';
import '../../00.common/network/network_message.dart';
import '../../00.common/network/network_room.dart';
import '../middleware/elemental.dart';
import '../foundation/energy.dart';
import '../middleware/dialog.dart';
import '../foundation/skill.dart';

import '../upper/cast_page.dart';
import '../upper/status_page.dart';

// 战斗行为类型
enum ConationType { attack, escape, parry, skill }

// 战斗行为数据结构
class GameAction {
  final int actionIndex;
  final int targetIndex;

  GameAction({required this.actionIndex, required this.targetIndex});

  Map<String, dynamic> toJson() {
    return {'actionIndex': actionIndex, 'targetIndex': targetIndex};
  }

  static GameAction fromJson(Map<String, dynamic> json) {
    return GameAction(
      actionIndex: json['actionIndex'],
      targetIndex: json['targetIndex'],
    );
  }
}

class NetCombatManager {
  static const _resultTitles = {
    TurnGameStep.victory: '胜利',
    TurnGameStep.defeat: '失败',
    TurnGameStep.escape: '逃跑',
    TurnGameStep.draw: '追击',
  };
  static const _resultContents = {
    TurnGameStep.victory: '你获得了胜利！',
    TurnGameStep.defeat: '很遗憾，你输了...',
    TurnGameStep.escape: '你成功逃脱了战斗',
    TurnGameStep.draw: '对方逃跑了',
  };
  static const _conationNames = {
    ConationType.attack: '攻击',
    ConationType.parry: '格挡',
    ConationType.skill: '技能',
    ConationType.escape: '逃跑',
  };
  static const _stepResultMapping = {
    1: {true: TurnGameStep.victory, false: TurnGameStep.defeat},
    -1: {true: TurnGameStep.defeat, false: TurnGameStep.victory},
    2: {true: TurnGameStep.escape, false: TurnGameStep.draw},
  };

  late final Elemental player;
  late final Elemental enemy;
  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});
  final ValueNotifier<TurnGameStep> gameStep = ValueNotifier(
    TurnGameStep.disconnect,
  );
  final ValueNotifier<String> infoList = ValueNotifier("");

  late int enemyIdentify;

  late final NetworkEngine networkEngine;

  NetCombatManager({required String userName, required RoomInfo roomInfo}) {
    _addCombatInfo(' '.padRight(100));
    networkEngine = NetworkEngine(
      userName: userName,
      roomInfo: roomInfo,
      navigatorHandler: pageNavigator,
      messageHandler: _handleMessage,
    );
  }

  void _handleMessage(NetworkMessage message) {
    switch (message.type) {
      case MessageType.accept:
        _handleAcceptMessage(message);
        break;
      case MessageType.search:
        _handleSearchMessage(message);
        break;
      case MessageType.match:
        _handleMatchMessage(message);
        break;
      case MessageType.resource:
        _handleRoleConfig(message);
        break;
      case MessageType.action:
        _handleGameAction(message);
        break;
      default:
        break;
    }
  }

  void _handleAcceptMessage(NetworkMessage message) {
    if (gameStep.value == TurnGameStep.disconnect) {
      gameStep.value = TurnGameStep.connected;
      networkEngine.sendNetworkMessage(
        MessageType.search,
        'Searching for opponent',
      );
    }
  }

  void _handleSearchMessage(NetworkMessage message) {
    // 检查游戏状态和消息发送者是否为对手
    if (gameStep.value == TurnGameStep.connected &&
        message.id != networkEngine.identify) {
      enemyIdentify = message.id;
      networkEngine.sendNetworkMessage(MessageType.match, 'Match to opponent');
      gameStep.value = TurnGameStep.frontConfig;
      _addCombatInfo("匹配到敌人${message.source}");
    }
  }

  void _handleMatchMessage(NetworkMessage message) {
    if (gameStep.value == TurnGameStep.connected &&
        message.id != networkEngine.identify) {
      enemyIdentify = message.id;
      gameStep.value = TurnGameStep.rearWait;
      _addCombatInfo("匹配到敌人${message.source}");
    }
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
    networkEngine.sendNetworkMessage(
      MessageType.resource,
      jsonEncode(
        Elemental.configsToJson(
          networkEngine.userName,
          configs,
          Random().nextInt(EnergyType.values.length),
        ),
      ),
    );
  }

  void _handleRoleConfig(NetworkMessage message) {
    final jsonData = jsonDecode(message.content);
    final isPlayer =
        (message.id == networkEngine.identify) &&
        (message.source == networkEngine.userName);

    if (gameStep.value == TurnGameStep.frontConfig && isPlayer) {
      player = Elemental.fromJson(jsonData);
      gameStep.value = TurnGameStep.frontWait;
    } else if (gameStep.value == TurnGameStep.frontWait && !isPlayer) {
      enemy = Elemental.fromJson(jsonData);
      _initCombat();
      gameStep.value = TurnGameStep.playerTrun;
    } else if ((gameStep.value == TurnGameStep.connected) && (!isPlayer)) {
      enemyIdentify = message.id;
      enemy = Elemental.fromJson(jsonData);
      gameStep.value = TurnGameStep.rearConfig;
      _addCombatInfo("匹配到敌人${message.source}");
    } else if (gameStep.value == TurnGameStep.rearWait && !isPlayer) {
      enemy = Elemental.fromJson(jsonData);
      gameStep.value = TurnGameStep.rearConfig;
    } else if (gameStep.value == TurnGameStep.rearConfig && isPlayer) {
      player = Elemental.fromJson(jsonData);

      _initCombat();
      gameStep.value = TurnGameStep.enemyTurn;
    }
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

  void _initCombat() {
    final info = gameStep.value == TurnGameStep.playerTrun
        ? "你的回合，请行动"
        : "敌人的回合，请等待";
    _addCombatInfo("\n$info\n");
    _applyPassiveEffects();
    _updatePrediction();
  }

  void _applyPassiveEffects() {
    player.applyAllPassiveEffect();
    enemy.applyAllPassiveEffect();
  }

  void conductAttack() => _handlePlayerAction(ConationType.attack);
  void conductEscape() => _handlePlayerAction(ConationType.escape);
  void conductParry() => _handlePlayerAction(ConationType.parry);
  void conductSkill() => _handlePlayerAction(ConationType.skill);

  void _handlePlayerAction(ConationType action) {
    if (gameStep.value.index >= TurnGameStep.victory.index) {
      return networkEngine.leavePage(); // 游戏结束后，点击任何按钮都会离开房间
    }

    switch (action) {
      case ConationType.attack:
        _sendGameAction(ConationType.attack.index, enemy.current);
        break;
      case ConationType.parry:
        _handlePlayerSkillTarget(-1);
        break;
      case ConationType.skill:
        _showSkillSelection();
        break;
      case ConationType.escape:
        _sendGameAction(ConationType.escape.index, player.current);
        _updateGameStepAfterAction(true, 2); // 直接处理，不需要服务器返回，防止服务器断开时无法退出
        break;
    }
  }

  void _showSkillSelection() {
    pageNavigator.value = (BuildContext context) {
      ElementalDialog.showSelectSkillDialog(
        context: context,
        skills: player.getAppointSkills(player.current),
        handleSkill: _handlePlayerSkillTarget,
      );
    };
  }

  void _handlePlayerSkillTarget(int skillIndex) {
    final actionIndex = ConationType.skill.index + skillIndex;
    final skills = player.getAppointSkills(player.current);
    final skill = skillIndex == -1
        ? SkillCollection.baseParry
        : skills[skillIndex];

    bool isSelf = _getSkillCategory(skill);
    bool isFront = _getSkillRange(skill);

    final elemental = isSelf ? player : enemy;

    if (isFront) {
      _sendGameAction(actionIndex, elemental.current);
    } else {
      _showEnergySelection(elemental, (i) => _sendGameAction(actionIndex, i));
    }
  }

  void _showEnergySelection(
    Elemental elemental,
    void Function(int) onSelected,
  ) {
    pageNavigator.value = (BuildContext context) {
      ElementalDialog.showSelectEnergyDialog(
        context: context,
        elemental: elemental,
        onSelected: onSelected,
        available: true,
      );
    };
  }

  void _sendGameAction(int actionIndex, int targetIndex) {
    if ((gameStep.value == TurnGameStep.playerTrun) ||
        (actionIndex == ConationType.escape.index)) {
      networkEngine.sendNetworkMessage(
        MessageType.action,
        jsonEncode(
          GameAction(actionIndex: actionIndex, targetIndex: targetIndex),
        ),
      );
    } else if (gameStep.value == TurnGameStep.enemyTurn) {
      _addCombatInfo('\n不是你的回合!\n');
    }
  }

  void _handleGameAction(NetworkMessage message) {
    if ((message.id != networkEngine.identify &&
            message.source != networkEngine.userName) &&
        (message.id != enemyIdentify)) {
      return _addCombatInfo('\n未知来源\n');
    }

    final isPlayer = message.id == networkEngine.identify;
    final action = GameAction.fromJson(jsonDecode(message.content));
    final actionType = _getActionType(action.actionIndex);

    if (isPlayer && (gameStep.value != TurnGameStep.playerTrun)) {
      return _addCombatInfo('\n服务器：不是你的回合\n');
    }

    _addCombatInfo('${message.source} 选择了 ${_conationNames[actionType]}');

    final actionHandlers = {
      ConationType.attack: () => _handleAttack(isPlayer),
      ConationType.escape: () => handleEscape(isPlayer),
      ConationType.parry: () => handleParry(isPlayer, action),
      ConationType.skill: () => _handleSkill(isPlayer, action),
    };

    actionHandlers[actionType]?.call();
  }

  ConationType _getActionType(int index) {
    return index < ConationType.values.length
        ? ConationType.values[index]
        : ConationType.skill;
  }

  void _handleAttack(bool isPlayer) {
    final attacker = isPlayer ? player : enemy;
    final defender = isPlayer ? enemy : player;
    final result = attacker.combatRequest(defender, defender.current, infoList);

    _handleActionResult(result, isPlayer);
  }

  void handleEscape(bool isPlayer) {
    if (!isPlayer) {
      _updateGameStepAfterAction(isPlayer, 2);
    }
  }

  void handleParry(bool isPlayer, GameAction action) {
    return _handleSkill(isPlayer, action);
  }

  void _handleSkill(bool isPlayer, GameAction action) {
    Elemental source = isPlayer ? player : enemy;

    final skillIndex = action.actionIndex - ConationType.skill.index;

    CombatSkill skill = (skillIndex == -1)
        ? SkillCollection.baseParry
        : source.getAppointSkills(source.current)[skillIndex];

    bool isSelf = _getSkillCategory(skill);
    bool isFront = _getSkillRange(skill);

    Elemental target = isSelf ? source : (isPlayer ? enemy : player);
    int targetIndex = isFront ? target.current : action.targetIndex;

    _addCombatInfo(
      "\n${source.getAppointName(source.current)} 施放了技能 《${skill.name}》，${target.getAppointName(targetIndex)} 获得效果 ${skill.description}",
    );

    int result = 0;
    target.appointSufferSkill(targetIndex, skill);

    switch (skill.id) {
      case SkillID.parry:
        _switchAppoint(target, targetIndex);
        break;
      case SkillID.woodActive_0:
        result = source.combatRequest(target, targetIndex, infoList);
        break;
      case SkillID.fireActive_0:
        _switchAppoint(target, targetIndex);
        final combatTarget = (target == player) ? enemy : player;
        result = target.combatRequest(
          combatTarget,
          combatTarget.current,
          infoList,
        );
        break;
      default:
    }

    _handleActionResult(result, isPlayer);
  }

  void _switchAppoint(Elemental elemental, int targetIndex) {
    elemental.switchAppoint(targetIndex);

    _addCombatInfo('\n${elemental.getAppointName(elemental.current)} 上场');

    _updatePrediction();
  }

  bool _getSkillCategory(CombatSkill skill) {
    if (skill.targetType == SkillTarget.selfFront ||
        skill.targetType == SkillTarget.selfAny) {
      return true;
    } else {
      return false;
    }
  }

  bool _getSkillRange(CombatSkill skill) {
    if (skill.targetType == SkillTarget.selfFront ||
        skill.targetType == SkillTarget.enemyFront) {
      return true; // 前排
    } else {
      return false; // 所有
    }
  }

  void _handleActionResult(int result, bool isPlayer) {
    final shouldSwitch = _shouldSwitchElemental(result, isPlayer);
    if (shouldSwitch != null && _switchNext(shouldSwitch)) {
      result = 0;
    }

    _updateGameStepAfterAction(isPlayer, result);
  }

  Elemental? _shouldSwitchElemental(int result, bool isPlayer) {
    if (result == 1) return isPlayer ? enemy : player;
    if (result == -1) return isPlayer ? player : enemy;
    return null;
  }

  bool _switchNext(Elemental elemental) {
    elemental.switchAliveByOrder();
    if (elemental.getAppointHealth(elemental.current) <= 0) return false;

    _addCombatInfo(
      '\n${elemental.name} 切换为 ${elemental.getAppointName(elemental.current)}',
    );
    _updatePrediction();
    return true;
  }

  void _updatePrediction() {
    player.confrontRequest(enemy);
    enemy.confrontRequest(player);
  }

  void _updateGameStepAfterAction(bool isPlayer, int result) {
    if (result == 0) {
      return _switchRound(isPlayer);
    } else {
      final mapping = _stepResultMapping[result];
      gameStep.value = mapping![isPlayer]!;
      _showGameResult();
    }
  }

  void _switchRound(bool isPlayer) {
    if (isPlayer) {
      gameStep.value = TurnGameStep.enemyTurn;
      _addCombatInfo('\n敌人的回合，请等待\n');
    } else {
      gameStep.value = TurnGameStep.playerTrun;
      _addCombatInfo('\n你的回合，请行动\n');
    }
  }

  void _showGameResult() {
    pageNavigator.value = (BuildContext context) {
      TemplateDialog.confirmDialog(
        context: context,
        title: _resultTitles[gameStep.value] ?? '',
        content: _resultContents[gameStep.value] ?? '',
        before: () {
          return true;
        },
        onTap: () {
          networkEngine.leavePage();
        },
        after: () {},
      );
    };
  }

  void _addCombatInfo(String message) {
    infoList.value += "$message\n";
  }
}
