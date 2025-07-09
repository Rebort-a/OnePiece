import 'package:flutter/material.dart';

import '../../00.common/game/gamer.dart';
import '../../00.common/widget/template_dialog.dart';
import '../../00.common/model/notifier.dart';
import '../middleware/elemental.dart';
import '../foundation/skill.dart';
import 'common.dart';
import 'dialog.dart';

abstract class BaseCombatManager {
  static const conationNames = {
    ConationType.attack: '攻击',
    ConationType.parry: '格挡',
    ConationType.skill: '技能',
    ConationType.escape: '逃跑',
  };
  static const resultTitles = {
    ResultType.victory: '胜利',
    ResultType.defeat: '失败',
    ResultType.escape: '逃跑',
    ResultType.draw: '追击',
  };
  static const resultContents = {
    ResultType.victory: '你获得了胜利！',
    ResultType.defeat: '很遗憾，你输了...',
    ResultType.escape: '你成功逃脱了战斗',
    ResultType.draw: '对方逃跑了',
  };
  static const stepResultMapping = {
    1: {true: ResultType.victory, false: ResultType.defeat},
    -1: {true: ResultType.defeat, false: ResultType.victory},
    2: {true: ResultType.escape, false: ResultType.draw},
    -2: {true: ResultType.draw, false: ResultType.escape},
  };

  ResultType combatResult = ResultType.continued;

  late final Elemental player;
  late final Elemental enemy;

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});
  final ValueNotifier<String> infoList = ValueNotifier("");
  final ValueNotifier<GamerType> currentGamer = ValueNotifier(GamerType.front);

  void initCombat(GamerType playerType) {
    final info = playerType == GamerType.front ? "你的回合，请行动" : "敌人的回合，请等待";
    addCombatInfo("\n$info\n");
    _applyPassiveEffects();
    _updatePrediction();
  }

  void _applyPassiveEffects() {
    player.applyAllPassiveEffect();
    enemy.applyAllPassiveEffect();
  }

  void _updatePrediction() {
    player.confrontRequest(enemy);
    enemy.confrontRequest(player);
  }

  void conductAttack() => handlePlayerAction(ConationType.attack);
  void conductEscape() => handlePlayerAction(ConationType.escape);
  void conductParry() => handlePlayerAction(ConationType.parry);
  void conductSkill() => handlePlayerAction(ConationType.skill);

  void handlePlayerAction(ConationType action);

  void handleAttack(bool isSelf) {
    final attacker = isSelf ? player : enemy;
    final defender = isSelf ? enemy : player;

    final result = attacker.combatRequest(defender, defender.current, infoList);
    handleActionResult(isSelf, result);
  }

  void showSkillSelection() {
    pageNavigator.value = (BuildContext context) {
      ElementalDialog.showSelectSkillDialog(
        context: context,
        skills: player.getAppointSkills(player.current),
        handleSkill: handlePlayerSkillTarget,
      );
    };
  }

  void handlePlayerSkillTarget(int skillIndex);

  bool getSkillCategory(CombatSkill skill) {
    return skill.targetType == SkillTarget.selfFront ||
        skill.targetType == SkillTarget.selfAny;
  }

  bool getSkillRange(CombatSkill skill) {
    return skill.targetType == SkillTarget.selfFront ||
        skill.targetType == SkillTarget.enemyFront;
  }

  void showEnergySelection(Elemental elemental, void Function(int) onSelected) {
    pageNavigator.value = (BuildContext context) {
      ElementalDialog.showSelectEnergyDialog(
        context: context,
        elemental: elemental,
        onSelected: onSelected,
        available: true,
      );
    };
  }

  void handleSkill(bool isSelf, GameAction action) {
    Elemental source = isSelf ? player : enemy;
    final skillIndex = action.actionIndex - ConationType.skill.index;
    CombatSkill skill = (skillIndex == -1)
        ? SkillCollection.baseParry
        : source.getAppointSkills(source.current)[skillIndex];

    bool targetIsSelf = getSkillCategory(skill);
    bool isFront = getSkillRange(skill);
    Elemental target = targetIsSelf ? source : (isSelf ? enemy : player);
    int targetIndex = isFront ? target.current : action.targetIndex;

    addCombatInfo(
      "\n${source.getAppointName(source.current)} 施放了技能 《${skill.name}》，"
      "${target.getAppointName(targetIndex)} 获得效果 ${skill.description}",
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

    handleActionResult(isSelf, result);
  }

  void _switchAppoint(Elemental elemental, int targetIndex) {
    elemental.switchAppoint(targetIndex);
    addCombatInfo('\n${elemental.getAppointName(elemental.current)} 上场');
    _updatePrediction();
  }

  void handleEscape(bool isSelf) {
    updateGameStepAfterAction(isSelf, 2);
  }

  void handleParry(bool isSelf, GameAction action) {
    return handleSkill(isSelf, action);
  }

  void handleActionResult(bool isSelf, int result) {
    final shouldSwitch = _shouldSwitchElemental(result, isSelf);
    if (shouldSwitch != null && _switchNext(shouldSwitch)) {
      result = 0;
    }
    updateGameStepAfterAction(isSelf, result);
  }

  Elemental? _shouldSwitchElemental(int result, bool isSelf) {
    if (result == 1) return isSelf ? enemy : player;
    if (result == -1) return isSelf ? player : enemy;
    return null;
  }

  bool _switchNext(Elemental elemental) {
    elemental.switchAliveByOrder();
    if (elemental.getAppointHealth(elemental.current) <= 0) return false;

    addCombatInfo(
      '\n${elemental.name} 切换为 ${elemental.getAppointName(elemental.current)}',
    );
    _updatePrediction();
    return true;
  }

  void updateGameStepAfterAction(bool isSelf, int result) {
    if (result == 0) {
      _switchRound(isSelf);
    } else {
      final mapping = stepResultMapping[result];
      combatResult = mapping![isSelf]!;
      _showGameResult();
    }
  }

  void _switchRound(bool isSelf) {
    addCombatInfo(isSelf ? '\n敌人的回合，请等待\n' : '\n你的回合，请行动\n');
    currentGamer.value = currentGamer.value.opponent;

    handleEnemyAction();
  }

  void handleEnemyAction();

  void _showGameResult() {
    pageNavigator.value = (BuildContext context) {
      TemplateDialog.confirmDialog(
        context: context,
        title: resultTitles[combatResult] ?? '',
        content: resultContents[combatResult] ?? '',
        before: () => true,
        onTap: () => leavePage(),
        after: () {},
      );
    };
  }

  void addCombatInfo(String message) {
    infoList.value += "$message\n";
  }

  void leavePage() {
    _navigateToBack();
  }

  void _navigateToBack() {
    pageNavigator.value = (context) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }
}
