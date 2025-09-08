import 'package:flutter/material.dart';
import '../base/energy.dart';
import 'foundation_combat_manager.dart';

import 'elemental.dart';
import 'common.dart';

class FoundationalCombatWidget {
  final FoundationalCombatManager combatManager;

  const FoundationalCombatWidget({required this.combatManager});

  List<Widget> buildPage() {
    return [
      buildBlankRegion(),
      buildInfoRegion(),
      buildMessageRegion(),
      buildButtonRegion(),
    ];
  }

  Widget buildBlankRegion() {
    return const SizedBox(height: 24);
  }

  Widget buildInfoRegion() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPlayerInfo()),
        Expanded(child: _buildEnemyInfo()),
      ],
    );
  }

  Widget _buildPlayerInfo() {
    return BattleInfoRegion(info: combatManager.player.preview);
  }

  Widget _buildEnemyInfo() {
    return BattleInfoRegion(info: combatManager.enemy.preview);
  }

  Widget buildMessageRegion() {
    return Expanded(
      child: ValueListenableBuilder<String>(
        valueListenable: combatManager.infoList,
        builder: (context, value, child) {
          return BattleMessageRegion(infoList: value);
        },
      ),
    );
  }

  Widget buildButtonRegion() {
    return BattleButtonRegion(combatManager: combatManager);
  }
}

class BattleInfoRegion extends StatelessWidget {
  final ElementalPreview info;

  const BattleInfoRegion({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildInfoRow(_buildInfoName(), _buildInfoEmoji()),
        _buildInfoRow(_buildInfoLabel('等级'), _buildInfoNotifier(info.level)),
        _buildInfoRow(_buildInfoLabel('生命值'), _buildInfoNotifier(info.health)),
        _buildInfoRow(_buildInfoLabel('攻击力'), _buildInfoNotifier(info.attack)),
        _buildInfoRow(_buildInfoLabel('防御力'), _buildInfoNotifier(info.defence)),
        _buildGlobalStatus(),
      ],
    );
  }

  Widget _buildInfoRow(Widget title, Widget content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [title],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [content],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoName() {
    return ValueListenableBuilder(
      valueListenable: info.name,
      builder: (context, value, child) {
        return Text(value);
      },
    );
  }

  Widget _buildInfoEmoji() {
    return ValueListenableBuilder(
      valueListenable: info.emoji,
      builder: (context, value, child) {
        return _getCombatEmoji(value);
      },
    );
  }

  static Widget _getCombatEmoji(double emoji) {
    if (emoji < 0.125) {
      return const Text('😢');
    } else if (emoji < 0.25) {
      return const Text('😞');
    } else if (emoji < 0.5) {
      return const Text('😮');
    } else if (emoji < 0.75) {
      return const Text('😐');
    } else if (emoji < 0.875) {
      return const Text('😊');
    } else {
      return const Text('😎');
    }
  }

  Widget _buildInfoLabel(String label) {
    return Text('$label: ');
  }

  Widget _buildInfoNotifier(ValueNotifier<int> notifier) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, value, child) {
        return TweenAnimationBuilder(
          tween: IntTween(begin: value, end: value),
          duration: const Duration(milliseconds: 500),
          builder: (context, int value, child) {
            return Text('$value', key: ValueKey<int>(value));
          },
        );
      },
    );
  }

  Widget _buildGlobalStatus() {
    return ValueListenableBuilder(
      valueListenable: info.resumes,
      builder: (context, value, child) {
        final front = value.isNotEmpty
            ? _buildElementBox(value.first)
            : const SizedBox.shrink();
        final backend = value.length > 1
            ? Wrap(children: value.skip(1).map(_buildElementBox).toList())
            : const SizedBox.shrink();

        return Column(children: [front, backend]);
      },
    );
  }

  Widget _buildElementBox(EnergyResume resume) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: resume.health > 0 ? Colors.blue : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(energyNames[resume.type.index]),
    );
  }
}

class BattleMessageRegion extends StatelessWidget {
  final String infoList;

  const BattleMessageRegion({super.key, required this.infoList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: SizedBox(
        height: 200,
        child: SingleChildScrollView(
          reverse: true,
          child: Text(infoList, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class BattleButtonRegion extends StatelessWidget {
  final FoundationalCombatManager combatManager;

  const BattleButtonRegion({super.key, required this.combatManager});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildButton(
          "${FoundationalCombatManager.conationNames[ConationType.attack]}",
          combatManager.conductAttack,
        ),
        _buildButton(
          "${FoundationalCombatManager.conationNames[ConationType.parry]}",
          combatManager.conductParry,
        ),
        _buildButton(
          "${FoundationalCombatManager.conationNames[ConationType.skill]}",
          combatManager.conductSkill,
        ),
        _buildButton(
          "${FoundationalCombatManager.conationNames[ConationType.escape]}",
          combatManager.conductEscape,
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(onPressed: onPressed, child: Text(text));
  }
}
