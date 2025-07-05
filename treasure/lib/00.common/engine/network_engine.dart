import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/template_dialog.dart';
import '../utils/custom_notifier.dart';
import '../network/network_message.dart';
import '../network/network_room.dart';

class NetworkEngine {
  final ListNotifier<NetworkMessage> messageList = ListNotifier([]);
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late Socket _socket;
  int identify = 0;

  final String userName;
  final RoomInfo roomInfo;
  final AlwaysNotifier<void Function(BuildContext)> navigatorHandler;
  final void Function(NetworkMessage message) messageHandler;

  NetworkEngine({
    required this.userName,
    required this.roomInfo,
    required this.navigatorHandler,
    required this.messageHandler,
  }) {
    messageList.addCallBack(_scrollToBottom);
    _connectToServer();
    _startKeyboard();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _connectToServer() async {
    try {
      _socket = await Socket.connect(roomInfo.address, roomInfo.port);
      _socket.listen(
        _handleSocketData,
        onError: _handleDisconnect,
        onDone: leavePage,
      );
    } catch (e) {
      _handleError("Failed to connect to server", e);
    }
  }

  void _handleSocketData(List<int> data) {
    try {
      final message = NetworkMessage.fromSocket(data);

      debugPrint(
        '${message.source} ${message.id} ${message.type} ${message.content}',
      );

      if ((message.type == MessageType.accept) && (identify == 0)) {
        identify = message.id;
        sendNetworkMessage(MessageType.notify, "join room success");
      } else if (message.type.index >= MessageType.notify.index) {
        messageList.add(message);
      }
      messageHandler(message);
    } catch (e) {
      _handleError("Failed to parse network message", e);
    }
  }

  void _handleDisconnect(Object e) {
    _handleError("Failed to connect to server", e);
    navigatorHandler.value = (context) {
      TemplateDialog.confirmDialog(
        context: context,
        title: "The connection has been disconnected",
        content: 'Coming out of the room soon',
        before: () {
          return true;
        },
        onTap: () {},
        after: () {
          leavePage();
        },
      );
    };
  }

  void _startKeyboard() {
    HardwareKeyboard.instance.addHandler(_handleChatKeyboardEvent);
  }

  void _stopKeyboard() {
    HardwareKeyboard.instance.removeHandler(_handleChatKeyboardEvent);
  }

  bool _handleChatKeyboardEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      sendInputText();
      return true;
    }
    return false;
  }

  void sendInputText() {
    final text = textController.text;
    if (text.isEmpty) return;

    sendNetworkMessage(MessageType.text, text);
    textController.clear();
  }

  void sendNetworkMessage(MessageType type, String content) {
    if (identify == 0) return;

    final message = NetworkMessage(
      id: identify,
      type: type,
      source: userName,
      content: content,
    );

    try {
      _socket.add(message.toSocketData());
    } catch (e) {
      _handleError("Send network message failed", e);
    }
  }

  void _handleError(String note, Object error) {
    debugPrint("$note: $error");
  }

  void leavePage() {
    // 断开服务器之前，发送最后一条消息
    sendNetworkMessage(MessageType.notify, 'leave room');

    navigatorHandler.value = (BuildContext context) {
      Navigator.of(context).pop();
    };

    // 停止监控键盘
    _stopKeyboard();

    //关闭 socket
    _socket.close();

    // // 移除所有监听器
    // gameStep.leavePage();
    // infoList.leavePage();
    // messageList.leavePage();

    // // 销毁控制器
    // textController.leavePage();
    // scrollController.leavePage();
  }
}
