import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widget/template_dialog.dart';
import '../model/notifier.dart';
import '../network/network_message.dart';
import '../network/network_room.dart';

class NetworkEngine {
  final ListNotifier<NetworkMessage> messageList = ListNotifier([]);
  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();

  late final Socket _socket;
  String _recvBuffer = '';
  final List<NetworkMessage> _sendBuffer = [];
  bool _isSending = false;

  bool _isDisposed = false;
  bool _isConnected = false;

  int identity = 0;

  final String userName;
  final RoomInfo roomInfo;
  final AlwaysNotifier<void Function(BuildContext)> navigatorHandler;
  void Function(NetworkMessage message) messageHandler = (_) {};

  NetworkEngine({
    required this.userName,
    required this.roomInfo,
    required this.navigatorHandler,
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

  Future<void> _connectToServer() async {
    _socket = await Socket.connect(roomInfo.address, roomInfo.port);
    _isConnected = true;
    _socket.listen(
      _handleSocketData,
      onError: (error) => _handleConnectionError(error),
      onDone: _handleSocketDone,
    );
  }

  void _handleSocketData(List<int> data) {
    if (_isConnected || _isDisposed) return;
    _recvBuffer += utf8.decode(data);
    _extractMessages();
  }

  Future<void> _extractMessages() async {
    // 网络消息都是JSON格式，{}成对出现
    int startIndex = 0;

    while (startIndex < _recvBuffer.length) {
      // 查找下一个 '{'
      int openBraceIndex = _recvBuffer.indexOf('{', startIndex);
      if (openBraceIndex == -1) break;

      // 查找对应的 '}'
      int closeBraceIndex = _findMatchingClosingBrace(openBraceIndex);
      if (closeBraceIndex == -1) break;

      // 提取完整的JSON字符串
      final String jsonStr = _recvBuffer.substring(
        openBraceIndex,
        closeBraceIndex + 1,
      );

      _processNetworkMessage(NetworkMessage.fromJsonString(jsonStr));

      // 更新起始位置
      startIndex = closeBraceIndex + 1;
    }

    // 移除已处理的消息
    if (startIndex > 0) {
      _recvBuffer = _recvBuffer.substring(startIndex);
    }
  }

  int _findMatchingClosingBrace(int startIndex) {
    int braceCount = 0;
    bool inString = false;

    for (int i = startIndex; i < _recvBuffer.length; i++) {
      final char = _recvBuffer[i];

      // 处理字符串内的转义字符
      if (char == '"' && (i == 0 || _recvBuffer[i - 1] != '\\')) {
        inString = !inString;
      }

      if (!inString) {
        if (char == '{') {
          braceCount++;
        } else if (char == '}') {
          braceCount--;
          if (braceCount == 0) return i;
        }
      }
    }
    return -1;
  }

  void _processNetworkMessage(NetworkMessage message) {
    debugPrint(
      '${message.source} ${message.id} ${message.type} ${message.content}',
    );

    if ((message.type == MessageType.accept) && (identity == 0)) {
      identity = message.id;
      sendNetworkMessage(MessageType.notify, "join in room");
    }

    if (message.type.index < MessageType.notify.index) {
      messageHandler(message);
    } else if (message.type.index >= MessageType.notify.index) {
      messageList.add(message);
    }
  }

  void _handleConnectionError(Object error) {
    _isConnected = false;
    navigatorHandler.value = (context) {
      TemplateDialog.confirmDialog(
        context: context,
        title: "Connection failed",
        content: "Could not connect to the server: ${error.toString()}",
        before: () => true,
        onTap: () {},
        after: () => leavePage(),
      );
    };
  }

  void _handleSocketDone() {
    _isConnected = false;
    if (_isDisposed) return;
    navigatorHandler.value = (context) {
      TemplateDialog.confirmDialog(
        context: context,
        title: "Disconnected",
        content: "You have been disconnected from the server",
        before: () => true,
        onTap: () {},
        after: () => leavePage(),
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
    final text = textController.text.trim();
    if (text.isEmpty) return;

    sendNetworkMessage(MessageType.text, text);
    textController.clear();
  }

  void sendNetworkMessage(MessageType type, String content) {
    if (identity == 0 || _isDisposed) return;

    final message = NetworkMessage(
      id: identity,
      type: type,
      source: userName,
      content: content,
    );

    _sendBuffer.add(message);
    _pushMessage();
  }

  Future<void> _pushMessage() async {
    if (_isConnected || _isSending || _sendBuffer.isEmpty) return;

    _isSending = true;

    while (_sendBuffer.isNotEmpty) {
      final message = _sendBuffer.first;
      _socket.add(message.toSocketData());
      await _socket.flush(); // 确保数据发送
      _sendBuffer.removeAt(0);
    }

    _isSending = false;
  }

  Future<void> leavePage() async {
    if (_isDisposed) return;

    _isDisposed = true;
    _stopKeyboard();

    sendNetworkMessage(MessageType.notify, 'leave room');

    while (_isConnected && _isSending) {
      await Future.delayed(const Duration(milliseconds: 20));
      await _pushMessage(); // 确保所有消息发送完毕
    }

    _socket.destroy();

    // 导航回上一页
    navigatorHandler.value = (BuildContext context) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };

    // 释放资源
    scrollController.dispose();
    textController.dispose();
    messageList.dispose();
  }
}
