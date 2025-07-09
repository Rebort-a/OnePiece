import 'package:flutter/material.dart';

import '../00.common/network/network_room.dart';
import '../02.lan_chat/net_main_page.dart';
import '../03.animal_chess/local_main_page.dart';
import '../03.animal_chess/net_main_page.dart';
import '../04.elemental_battle/upper/main_page.dart';
import '../04.elemental_battle/upper/net_combat_page.dart';
import '../05.gobang/local_main_page.dart';
import '../05.gobang/net_main_page.dart';

enum LocalItemType { animalChess, elementalBattle, gobang }

enum NetItemType { onlyChat, animalChess, elementalBattle, gobang }

class RouteManager {
  static void navigateToLocalPage(
    BuildContext context,
    LocalItemType routeType,
  ) {
    switch (routeType) {
      case LocalItemType.animalChess:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => LoaclAnimalChessPage()));
        break;
      case LocalItemType.elementalBattle:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => MapPage()));
        break;
      case LocalItemType.gobang:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => LocalGomokuPage()));
    }
  }

  static void navigateToNetPage(
    BuildContext context,
    String userName,
    RoomInfo roomInfo,
  ) {
    switch (NetItemType.values[roomInfo.type]) {
      case NetItemType.onlyChat:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NetChatPage(userName: userName, roomInfo: roomInfo),
          ),
        );
        break;
      case NetItemType.animalChess:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                NetAnimalChessPage(userName: userName, roomInfo: roomInfo),
          ),
        );
        break;
      case NetItemType.elementalBattle:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                NetCombatPage(userName: userName, roomInfo: roomInfo),
          ),
        );
        break;
      case NetItemType.gobang:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                NetGomokuPage(userName: userName, roomInfo: roomInfo),
          ),
        );
    }
  }
}
