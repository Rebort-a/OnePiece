// local_combat_page.dart
import 'package:flutter/material.dart';

import '../../00.common/game/gamer.dart';
import '../middleware/base_combat_page.dart';
import '../middleware/elemental.dart';
import 'local_combat_manager.dart';

class LocalCombatPage extends StatelessWidget {
  late final LocalCombatManager _combatManager;

  LocalCombatPage({
    super.key,
    required Elemental player,
    required Elemental enemy,
    required GamerType playerType,
  }) {
    _combatManager = LocalCombatManager(
      player: player,
      enemy: enemy,
      playerType: playerType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("战斗"),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            ...BaseCombatPage(combatManager: _combatManager).buildPage(),
            _buildBlankRegion(),
          ],
        ),
      ),
    );
  }

  Widget _buildBlankRegion() => const SizedBox(height: 192);
}
