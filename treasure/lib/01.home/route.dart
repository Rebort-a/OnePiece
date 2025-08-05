import 'package:flutter/material.dart';

import '../00.common/network/network_room.dart';
import '../02.lan_chat/net_page.dart';
import '../03.animal_chess/local_page.dart';
import '../03.animal_chess/net_page.dart';
import '../04.elemental_battle/upper/maze_page.dart';
import '../04.elemental_battle/upper/net_combat_page.dart';
import '../05.gobang/local_page.dart';
import '../05.gobang/net_page.dart';
import '../06.greedy_snake/local_page.dart';
import '../06.greedy_snake/net_page.dart';
import '../07.weiqi/local_page.dart';
import '../07.weiqi/net_page.dart';

enum LocalItemType { animalChess, elementalBattle, gobang, greedySnake, weiqi }

enum NetItemType {
  onlyChat,
  animalChess,
  elementalBattle,
  gobang,
  greedySnake,
  weiqi,
}

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
        ).push(MaterialPageRoute(builder: (_) => MazePage()));
        break;
      case LocalItemType.gobang:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => LocalGomokuPage()));
        break;
      case LocalItemType.greedySnake:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => LocalGreedySnakePage()));
        break;
      case LocalItemType.weiqi:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => GoLocalPage()));
        break;
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
        break;
      case NetItemType.greedySnake:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                NetGreedySnakePage(userName: userName, roomInfo: roomInfo),
          ),
        );
        break;
      case NetItemType.weiqi:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GoNetPage(userName: userName, roomInfo: roomInfo),
          ),
        );
        break;
    }
  }
}
