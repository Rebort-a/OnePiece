import 'package:flutter/material.dart';
import 'package:treasure/04.elemental_battle/foundation/energy.dart';

import '../../00.common/game/gamer.dart';
import '../../00.common/widget/template_dialog.dart';
import '../../00.common/model/notifier.dart';
import '../middleware/elemental.dart';
import '../foundation/skill.dart';
import 'common.dart';
import 'dialog.dart';

abstract class FoundationalCombatManager {
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
    CombatResult.attackerWin: {
      true: ResultType.victory,
      false: ResultType.defeat,
    },
    CombatResult.defenderWin: {
      true: ResultType.defeat,
      false: ResultType.victory,
    },
    CombatResult.attackerEscape: {
      true: ResultType.escape,
      false: ResultType.draw,
    },
    CombatResult.defenderEscape: {
      true: ResultType.draw,
      false: ResultType.escape,
    },
  };

  ResultType combatResult = ResultType.continued;

  late final Elemental player;
  late final Elemental enemy;

  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});
  final ValueNotifier<String> infoList = ValueNotifier("");
  final ValueNotifier<TurnGamerType> currentGamer = ValueNotifier(
    TurnGamerType.front,
  );

  void initCombat(TurnGamerType playerType) {
    final info = playerType == TurnGamerType.front ? "你的回合，请行动" : "敌人的回合，请等待";
    addCombatInfo(
      "${' '.padRight(100)}\n"
      "$info\n",
    );
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

    addCombatInfo('${attacker.getAppointName(attacker.current)} 选择了 攻击');

    CombatResult result = attacker.combatRequest(
      defender,
      defender.current,
      infoList,
    );
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

  void showEnergySelection(
    Elemental elemental,
    void Function(EnergyType) onSelected,
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

  void handleSkill(bool isSelf, GameAction action) {
    Elemental source = isSelf ? player : enemy;
    final skillIndex = action.actionIndex - ConationType.skill.index;
    CombatSkill skill = (skillIndex == -1)
        ? SkillCollection.baseParry
        : source.getAppointSkills(source.current)[skillIndex];

    bool targetIsSelf = getSkillCategory(skill);
    bool isFront = getSkillRange(skill);
    Elemental target = targetIsSelf ? source : (isSelf ? enemy : player);
    EnergyType targetIndex = isFront
        ? target.current
        : EnergyType.values[action.targetIndex];

    addCombatInfo(
      "${source.getAppointName(source.current)} 施放了技能 ${skill.name} \n"
      "${target.getAppointName(targetIndex)} 获得效果 ${skill.description}",
    );

    CombatResult result = CombatResult.undecided;
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

  void _switchAppoint(Elemental elemental, EnergyType targetIndex) {
    if (targetIndex != elemental.current) {
      elemental.switchAppoint(targetIndex);
      addCombatInfo('${elemental.getAppointName(elemental.current)} 上场');
    }
  }

  void handleEscape(bool isSelf) {
    updateGameStepAfterAction(isSelf, CombatResult.attackerEscape);
  }

  void handleParry(bool isSelf, GameAction action) {
    return handleSkill(isSelf, action);
  }

  void handleActionResult(bool isSelf, CombatResult result) {
    final shouldSwitch = _shouldSwitchElemental(result, isSelf);
    if (shouldSwitch != null && _switchNext(shouldSwitch)) {
      result = CombatResult.undecided;
    }
    updateGameStepAfterAction(isSelf, result);
  }

  Elemental? _shouldSwitchElemental(CombatResult result, bool isSelf) {
    if (result == CombatResult.attackerWin) return isSelf ? enemy : player;
    if (result == CombatResult.defenderWin) return isSelf ? player : enemy;
    return null;
  }

  bool _switchNext(Elemental elemental) {
    if (!elemental.switchAliveByOrder()) return false;

    addCombatInfo(
      '${elemental.baseName} 切换为 ${elemental.getAppointName(elemental.current)}',
    );
    return true;
  }

  void updateGameStepAfterAction(bool isSelf, CombatResult result) {
    if (result == CombatResult.undecided) {
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
    _updatePrediction();
    handleEnemyAction();
  }

  void handleEnemyAction();

  void _showGameResult() {
    pageNavigator.value = (BuildContext context) {
      TemplateDialog.promptDialog(
        context: context,
        title: resultTitles[combatResult] ?? '',
        content: resultContents[combatResult] ?? '',
        before: () => true,
        after: leavePage,
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
        Navigator.of(context).pop(combatResult);
      }
    };
  }
}
