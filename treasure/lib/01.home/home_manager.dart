import 'package:flutter/material.dart';
import 'package:treasure/01.home/route.dart';

import '../00.common/model/notifier.dart';
import '../00.common/network/broadcast_discovery.dart';
import '../00.common/network/network_message.dart';
import '../00.common/network/network_room.dart';
import '../00.common/network/socket_server.dart';
import 'dialog.dart';

class CreatedRoomInfo extends RoomInfo {
  final SocketServer server;

  CreatedRoomInfo({
    required super.name,
    required super.type,
    required super.address,
    required super.port,
    required this.server,
  });
}

class HomeManager {
  final AlwaysNotifier<void Function(BuildContext)> pageNavigator =
      AlwaysNotifier((_) {});
  final ListNotifier<CreatedRoomInfo> createdRooms = ListNotifier([]);
  final ListNotifier<RoomInfo> othersRooms = ListNotifier([]);

  final Discovery _discovery = Discovery();

  HomeManager() {
    _discovery.startReceive(_handleReceivedMessage);
  }

  void _handleReceivedMessage(String address, List<int> data) {
    NetworkMessage message = NetworkMessage.fromSocket(data);
    if (message.type == MessageType.broadcast) {
      RoomState operation = RoomInfo.getOperationFromString(message.content);
      int port = RoomInfo.getPortFromString(message.content);

      if (operation == RoomState.stop) {
        othersRooms.removeWhere(
          (room) =>
              room.name == message.source &&
              room.address == address &&
              room.port == port,
        );
      } else if (operation == RoomState.start) {
        int type = RoomInfo.getTypeFromString(message.content);
        RoomInfo newRoom = RoomInfo(
          name: message.source,
          type: type,
          address: address,
          port: port,
        );
        bool isMyRoom = createdRooms.value.any(
          (room) => room.name == newRoom.name && room.port == newRoom.port,
        );
        bool isOtherRoom = othersRooms.value.any(
          (room) =>
              room.name == newRoom.name &&
              room.address == newRoom.address &&
              room.port == newRoom.port,
        );

        if ((!isMyRoom) && (!isOtherRoom)) {
          othersRooms.add(newRoom);
        }
      }
    }
  }

  void showCreateRoomDialog() {
    pageNavigator.value = (BuildContext context) {
      RoomDialog.showCreateRoomDialog(context: context, onConfirm: _createRoom);
    };
  }

  void _createRoom(String roomName, NetItemType roomType) async {
    SocketServer server = SocketServer(
      roomName: roomName,
      roomType: roomType.index,
    );

    await server.start();

    createdRooms.add(
      CreatedRoomInfo(
        name: roomName,
        type: roomType.index,
        address: 'localhost',
        port: server.port,
        server: server,
      ),
    );
  }

  void stopAllCreatedRooms() {
    for (var room in createdRooms.value) {
      room.server.stop();
    }
    createdRooms.clear();
  }

  void stopCreatedRoom(int index) {
    var room = createdRooms.value[index];
    room.server.stop();
    createdRooms.removeAt(index);
  }

  void showJoinRoomDialog(RoomInfo room) {
    pageNavigator.value = (BuildContext context) {
      RoomDialog.showJoinRoomDialog(
        context: context,
        room: room,
        onConfirm: _joinRoom,
      );
    };
  }

  void _joinRoom(String userName, RoomInfo room, BuildContext context) {
    pageNavigator.value = (BuildContext context) {
      RouteManager.navigateToNetPage(context, userName, room);
    };
  }

  void routeLocal(LocalItemType routeType) {
    pageNavigator.value = (BuildContext context) {
      RouteManager.navigateToLocalPage(context, routeType);
    };
  }
}
