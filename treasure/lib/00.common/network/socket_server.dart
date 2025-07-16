import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'broadcast_discovery.dart';
import 'network_message.dart';
import 'network_room.dart';

// 1.创建socket服务器，定时广播房间信息和端口号
// 2.等待客户端连接，分配id，转发信息
// 3.停止广播，发送结束信息，关闭连接，移除客户端

class SocketServer {
  static const _discoveryInterval = Duration(seconds: 1);

  late final Timer _timer;
  late final ServerSocket _server;
  final Set<Socket> _clients = {};
  int clientCounter = 0;

  final String roomName;
  final int roomType;

  SocketServer({required this.roomName, required this.roomType});

  Future<void> start() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
      _server.listen(_handleClientConnect);

      _startBroadcast();
    } on SocketException catch (e) {
      throw Exception("Failed to start server: ${e.message}");
    }
  }

  int get port => _server.port;

  void _startBroadcast() {
    _timer = Timer.periodic(_discoveryInterval, (timer) {
      Broadcast.sendMessage(
        _createRoomInfoMessage(RoomState.start).toSocketData(),
      );
    });
  }

  void _handleClientConnect(Socket client) {
    clientCounter = clientCounter + 1;
    _clients.add(client);
    _sendAcceptMessage(client, clientCounter);

    client.listen(
      _broadcastMessage,
      onDone: () => _removeClient(client),
      onError: (_) => _removeClient(client),
      cancelOnError: true,
    );
  }

  void _sendAcceptMessage(Socket client, int id) {
    _sendMessageToClient(
      client,
      NetworkMessage(
        id: id,
        type: MessageType.accept,
        source: roomName,
        content: 'server',
      ).toSocketData(),
    );
  }

  void _broadcastMessage(List<int> data) {
    for (final client in _clients) {
      _sendMessageToClient(client, data);
    }
  }

  Future<void> _sendMessageToClient(Socket client, List<int> data) async {
    if (_clients.contains(client)) {
      try {
        client.add(data);
        await client.flush();
      } catch (e) {
        debugPrint("Socket error: $e");
      }
    }
  }

  void _removeClient(Socket client) {
    _clients.remove(client);
    client.close();
  }

  void stop() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    Broadcast.sendMessage(
      _createRoomInfoMessage(RoomState.stop).toSocketData(),
    );
    _closeResources();
  }

  NetworkMessage _createRoomInfoMessage(RoomState operation) {
    return NetworkMessage(
      id: 0,
      type: MessageType.broadcast,
      source: roomName,
      content: RoomInfo.configToString(port, roomType, operation),
    );
  }

  void _closeResources() {
    if (_clients.isNotEmpty) {
      for (var client in _clients) {
        client.close();
      }
      _clients.clear();
    }

    _server.close();
  }
}
