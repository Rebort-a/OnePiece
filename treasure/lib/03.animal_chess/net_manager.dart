import 'dart:convert';
import 'package:treasure/00.common/widget/dialog/template_dialog.dart';

import '../00.common/game/gamer.dart';
import '../00.common/engine/net_turn_engine.dart';
import '../00.common/game/step.dart';
import '../00.common/network/network_message.dart';
import '../00.common/network/network_room.dart';

import 'base.dart';
import 'foundation_manager.dart';

class NetManager extends FoundationalManager {
  late final NetTurnGameEngine netTurnEngine;

  NetManager({required String userName, required RoomInfo roomInfo}) {
    // 构建网络回合制游戏对战引擎
    netTurnEngine = NetTurnGameEngine(
      userName: userName,
      roomInfo: roomInfo,
      navigatorHandler: pageNavigator,
      searchHandler: _searchHandler,
      resourceHandler: _resourceHandler,
      actionHandler: _actionHandler,
      exitHandler: _exitHandler,
    );
  }

  void _searchHandler() {
    initGame();
    netTurnEngine.sendNetworkMessage(
      MessageType.resource,
      _mapToString(),
    ); // 然后通过网络发送
  }

  void _resourceHandler(GameStep step, NetworkMessage message) {
    if (step == GameStep.connected || step == GameStep.rearWait) {
      _stringToMap(message.content);
      resetGameState();
      netTurnEngine.sendNetworkMessage(MessageType.resource, "ok");
    }
  }

  void _actionHandler(bool isSelf, NetworkMessage message) {
    if (netTurnEngine.gameStep.value == GameStep.action) {
      int index = jsonDecode(message.content)['index'];
      if (index >= 0 && index < displayMap.length) {
        if (currentGamer.value == netTurnEngine.playerType && isSelf) {
          // 自己回合中，自己行动才能生效
          selectGrid(index);
        } else if (!isSelf) {
          // 敌人行为直接生效，然后回合会切换为自己回合
          selectGrid(index);
        }
      }
    }
  }

  void _exitHandler() {}

  String _mapToString() {
    // 只序列化动物分布信息
    List<List<int>> animalDistribution = displayMap.value
        .asMap()
        .entries
        .where((entry) => entry.value.value.hasAnimal)
        .map((entry) {
          final animal = entry.value.value.animal!;
          return [
            entry.key, // 坐标位置
            animal.owner.index, // 所属玩家索引
            animal.type.index, // 动物类型索引
            animal.isHidden ? 1 : 0, // 是否隐藏
          ];
        })
        .toList();

    return jsonEncode({
      'boardLevel': boardLevel,
      'animals': animalDistribution,
    });
  }

  void _stringToMap(String content) {
    final jsonData = jsonDecode(content);
    boardLevel = jsonData['boardLevel'];

    // 初始化棋牌
    setupBoard();

    // 放置动物
    final animalDistribution = jsonData['animals'] as List<dynamic>;
    for (final animalData in animalDistribution) {
      final data = animalData as List<dynamic>;
      final index = data[0] as int;
      final owner = TurnGamerType.values[data[1] as int];
      final type = AnimalType.values[data[2] as int];
      final isHidden = data[3] == 1;

      placeAnimalByIndex(
        index,
        Animal(type: type, owner: owner, isHidden: isHidden),
      );
    }
  }

  void sendActionMessage(int index) {
    if ((netTurnEngine.gameStep.value == GameStep.action &&
            currentGamer.value == netTurnEngine.playerType) ||
        index == -1) {
      netTurnEngine.sendNetworkMessage(
        MessageType.action,
        jsonEncode({'index': index}),
      );
    }
  }

  @override
  void showChessResult(bool isRedWin) {
    netTurnEngine.gameStep.value = GameStep.gameOver;
    pageNavigator.value = (context) {
      DialogTemplate.promptDialog(
        context: context,
        title: '游戏结束',
        content: "${isRedWin ? "红" : "蓝"}方获胜！",
        before: () => true,
        after: () {
          netTurnEngine.leavePage();
        },
      );
    };
  }

  @override
  void leavePage() {
    netTurnEngine.leavePage();
  }
}
