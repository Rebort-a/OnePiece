import 'dart:convert';
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
  // 新增：用于存储不完整消息的缓冲区
  String _socketDataBuffer = '';
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
    // 将字节数据转换为字符串并添加到缓冲区
    _socketDataBuffer += utf8.decode(data);

    // 尝试从缓冲区中提取完整的消息
    _extractAndProcessMessages();
  }

  void _extractAndProcessMessages() {
    // 简单的消息分割算法：查找完整的 JSON 对象
    // 这里假设每个 JSON 消息都以 '{' 开始，以 '}' 结束
    int startIndex = 0;

    while (startIndex < _socketDataBuffer.length) {
      // 查找下一个 '{'
      int openBraceIndex = _socketDataBuffer.indexOf('{', startIndex);
      if (openBraceIndex == -1) {
        // 没有更多完整的消息
        break;
      }

      // 查找对应的 '}'
      int closeBraceIndex = _findMatchingClosingBrace(openBraceIndex);
      if (closeBraceIndex == -1) {
        // 没有找到匹配的 '}'，说明消息不完整
        break;
      }

      // 提取完整的 JSON 字符串
      final String jsonStr = _socketDataBuffer.substring(
        openBraceIndex,
        closeBraceIndex + 1,
      );

      try {
        final message = NetworkMessage.fromString(jsonStr);
        debugPrint(
          '${message.source} ${message.id} ${message.type} ${message.content}',
        );

        if ((message.type == MessageType.accept) && (identify == 0)) {
          identify = message.id;
          sendNetworkMessage(MessageType.notify, "join in room");
        }
        if (message.type.index < MessageType.notify.index) {
          messageHandler(message);
        } else if (message.type.index >= MessageType.notify.index) {
          messageList.add(message);
        }
      } catch (e) {
        _handleError("Failed to parse network message", e);
      }

      // 更新起始位置，继续查找下一个消息
      startIndex = closeBraceIndex + 1;
    }

    // 移除已经处理的消息
    if (startIndex > 0) {
      _socketDataBuffer = _socketDataBuffer.substring(startIndex);
    }
  }

  int _findMatchingClosingBrace(int startIndex) {
    int braceCount = 0;
    for (int i = startIndex; i < _socketDataBuffer.length; i++) {
      if (_socketDataBuffer[i] == '{') {
        braceCount++;
      } else if (_socketDataBuffer[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          return i;
        }
      }
    }
    return -1; // 没有找到匹配的 '}'
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

    // 停止监控键盘
    _stopKeyboard();

    // //关闭 socket
    // _socket.close();

    navigatorHandler.value = (BuildContext context) {
      Navigator.of(context).pop();
    };

    // // 移除所有监听器
    // gameStep.dispose();
    // infoList.dispose();
    // messageList.dispose();

    // // 销毁控制器
    // textController.dispose();
    // scrollController.dispose();
  }
}
