import 'dart:math';
import 'package:flutter/material.dart';
import 'package:treasure/04.elemental_battle/middleware/dialog.dart';

import '../../00.common/utils/template_dialog.dart';
import '../../00.common/utils/custom_notifier.dart';
import '../middleware/common.dart';
import '../middleware/elemental.dart';
import '../foundation/skill.dart';

// 战斗行为类型
enum ActionType { attack, parry, skill, escape }

class LocalCombatManager {
  final _random = Random(); // 随机生成器

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {}); // 供检测是否需要弹出界面

  final ValueNotifier<String> combatMessage = ValueNotifier<String>(
    ' '.padRight(100),
  ); // 供消息区域使用

  final Elemental player; // 玩家
  final Elemental enemy; // 敌人
  final bool offensive; // 先手

  ResultType combatResult = ResultType.continued; // 保存战斗结果

  LocalCombatManager({
    required this.player,
    required this.enemy,
    required this.offensive,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 战斗开始前，为交战双方施加所有已学习的被动技能效果
      player.applyAllPassiveEffect();
      enemy.applyAllPassiveEffect();

      _handleUpdatePrediction();

      if (offensive) {
        combatMessage.value += ("\n你获得了先手\n");
      } else {
        combatMessage.value += ("\n敌人获得了先手\n");
        _handleEnemyAction();
      }
    });
  }

  void conductAttack() {
    _handlePlayerAction(ActionType.attack);
  }

  void conductParry() {
    _handlePlayerAction(ActionType.parry);
  }

  void conductSkill() {
    _handlePlayerAction(ActionType.skill);
  }

  void conductEscape() {
    _handlePlayerAction(ActionType.escape);
  }

  void _handlePlayerAction(ActionType command) {
    if (combatResult != ResultType.continued) {
      _navigateToHomePage(combatResult);
    } else {
      combatMessage.value += ('\n${player.name} 选择了 $command\n');
      switch (command) {
        case ActionType.attack:
          _handleActionResult(
            player.combatRequest(enemy, enemy.current, combatMessage),
          );
          if (combatResult == ResultType.continued) {
            _handleEnemyAction();
          }
          break;
        case ActionType.parry:
          _handlePlayerSkillTarget(-1);
          break;
        case ActionType.skill:
          pageNavigator.value = (BuildContext context) {
            ElementalDialog.showSelectSkillDialog(
              context: context,
              skills: player.getAppointSkills(player.current),
              handleSkill: _handlePlayerSkillTarget,
            );
          };
          break;
        case ActionType.escape:
          _handleActionResult(-2);
          break;
      }
    }
  }

  void _handlePlayerSkillTarget(int skillIndex) {
    final skills = player.getAppointSkills(player.current);
    final skill = skillIndex == -1
        ? SkillCollection.baseParry
        : skills[skillIndex];

    switch (skill.targetType) {
      case SkillTarget.selfFront:
        _handlePlayerSkill(skill, player, player.current);
        break;
      case SkillTarget.selfAny:
        pageNavigator.value = (BuildContext context) {
          ElementalDialog.showSelectEnergyDialog(
            context: context,
            elemental: player,
            onSelected: (int index) {
              _handlePlayerSkill(skill, player, index);
            },
            available: true,
          );
        };
        break;
      case SkillTarget.enemyFront:
        _handlePlayerSkill(skill, enemy, enemy.current);
        break;
      case SkillTarget.enemyAny:
        pageNavigator.value = (BuildContext context) {
          ElementalDialog.showSelectEnergyDialog(
            context: context,
            elemental: enemy,
            onSelected: (int index) {
              _handlePlayerSkill(skill, enemy, index);
            },
            available: true,
          );
        };
        break;
    }
  }

  void _handlePlayerSkill(
    CombatSkill skill,
    Elemental targetElemental,
    int targetIndex,
  ) {
    int result = 0;

    targetElemental.appointSufferSkill(targetIndex, skill);

    combatMessage.value +=
        ('${player.getAppointName(player.current)} 施放了 ${skill.name}, ${targetElemental.getAppointName(targetIndex)} 获得效果 ${skill.description}\n');

    if (skill.id == SkillID.parry) {
      _switchAppoint(targetElemental, targetIndex);
    } else if (skill.id == SkillID.woodActive_0) {
      result = player.combatRequest(
        targetElemental,
        targetIndex,
        combatMessage,
      );
    } else if (skill.id == SkillID.fireActive_0) {
      _switchAppoint(targetElemental, targetIndex);
      result = player.combatRequest(enemy, enemy.current, combatMessage);
    }

    _handleActionResult(result);
    if (combatResult == ResultType.continued) {
      _handleEnemyAction();
    }
  }

  ActionType _getEnemyAction() {
    // 敌方的行为是根据概率随机的
    int randVal = _random.nextInt(128);
    if (randVal < 1) {
      return ActionType.escape;
    } else if (randVal < 16) {
      return ActionType.parry;
    } else if (randVal < 32) {
      return ActionType.skill;
    } else {
      return ActionType.attack;
    }
  }

  void _handleEnemyAction() {
    ActionType command = ActionType.attack;

    if (enemy.getAppointSkills(enemy.current)[1].learned) {
      command = _getEnemyAction();
    }

    combatMessage.value +=
        ('${enemy.getAppointName(enemy.current)} 选择了 $command\n');
    switch (command) {
      case ActionType.attack:
        _handleActionResult(
          -enemy.combatRequest(player, player.current, combatMessage),
        );
        break;
      case ActionType.parry:
        _handleEnemySkill(SkillCollection.baseParry);
        break;
      case ActionType.skill:
        _handleEnemySkill(SkillCollection.totalSkills[enemy.current][1]);
        break;
      case ActionType.escape:
        _handleActionResult(2);
        break;
    }
  }

  void _handleEnemySkill(CombatSkill skill) {
    Elemental targetElemental = (skill.targetType == SkillTarget.enemyFront)
        ? player
        : enemy;

    targetElemental.appointSufferSkill(targetElemental.current, skill);

    combatMessage.value +=
        ('${enemy.preview.name.value} 施放了 ${skill.name}, ${targetElemental.preview.name.value} 获得效果 ${skill.description}\n');

    int result = 0;

    if (skill.id == SkillID.woodActive_0) {
      result = enemy.combatRequest(enemy, enemy.current, combatMessage);
    } else if (skill.id == SkillID.fireActive_0) {
      result = enemy.combatRequest(player, player.current, combatMessage);
    }

    _handleActionResult(-result);
  }

  void _handleActionResult(int result) {
    _handleUpdatePrediction();

    if (result == 1) {
      result = _switchNext(enemy, result);
    } else if (result == -1) {
      result = _switchNext(player, result);
    }

    switch (result) {
      case 1:
        combatResult = ResultType.victory;
        pageNavigator.value = _showCombatResult;
        break;
      case -1:
        combatResult = ResultType.defeat;
        pageNavigator.value = _showCombatResult;
        break;
      case -2:
        combatResult = ResultType.escape;
        pageNavigator.value = _showCombatResult;
        break;
      case 2:
        combatResult = ResultType.draw;
        pageNavigator.value = _showCombatResult;
        break;
    }
  }

  void _switchAppoint(Elemental elemental, int index) {
    elemental.switchAppoint(index);
    combatMessage.value +=
        '${elemental.name} 切换为 ${elemental.preview.name.value}\n';
    _handleUpdatePrediction();
  }

  int _switchNext(Elemental elemental, int result) {
    String lastName = elemental.preview.name.value;
    elemental.switchAliveByOrder();
    if (elemental.preview.health.value > 0) {
      combatMessage.value +=
          '${elemental.name} 切换为 ${elemental.preview.name.value}\n';

      pageNavigator.value = (BuildContext context) {
        TemplateDialog.snackBarDialog(
          context,
          '连一刻都没有为 $lastName 的死亡哀悼，立刻赶到战场的是 ${elemental.preview.name.value}',
        );
      };
      result = 0;
    }
    _handleUpdatePrediction();
    return result;
  }

  void _handleUpdatePrediction() {
    player.confrontRequest(enemy);
    enemy.confrontRequest(player);
  }

  _showCombatResult(BuildContext context) {
    String title;
    String content;

    switch (combatResult) {
      case ResultType.victory:
        title = '胜利';
        content = '你获得了胜利';
        break;
      case ResultType.defeat:
        title = '失败';
        content = '你失败了';
        break;
      case ResultType.escape:
        title = '逃跑';
        content = '你逃跑了';
        break;
      case ResultType.draw:
        title = '快追';
        content = '敌人逃跑了';
        break;
      default:
        title = '';
        content = '';
        break;
    }

    TemplateDialog.confirmDialog(
      context: context,
      title: title,
      content: content,
      before: () {
        return true;
      },
      onTap: () {
        _navigateToHomePage(combatResult);
      },
      after: () => {},
    );
  }

  _navigateToHomePage(ResultType combatResult) {
    pageNavigator.value = (BuildContext context) {
      Navigator.pop(context, combatResult);
    };
  }
}
