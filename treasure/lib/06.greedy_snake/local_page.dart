import 'package:flutter/material.dart';

import 'foundation_widget.dart';
import 'local_manager.dart';

class LocalGreedySnakePage extends StatelessWidget {
  final manager = LocalManager();

  LocalGreedySnakePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GameScreen(manager: manager, showStateButton: true);
  }
}
