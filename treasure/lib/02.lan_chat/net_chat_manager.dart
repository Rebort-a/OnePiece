import 'package:flutter/material.dart';

import '../00.common/engine/network_engine.dart';
import '../00.common/model/notifier.dart';
import '../00.common/network/network_room.dart';

class NetChatManager {
  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});
  late final NetworkEngine networkEngine;
  NetChatManager({required String userName, required RoomInfo roomInfo}) {
    networkEngine = NetworkEngine(
      userName: userName,
      roomInfo: roomInfo,
      navigatorHandler: pageNavigator,
      messageHandler: (message) {},
    );
  }
}
