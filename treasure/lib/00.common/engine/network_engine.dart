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

  int identify = 0;

  bool _isDisposed = false;
  bool _isSocketConnected = false;

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
    if (_isDisposed) return;

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
    if (_isDisposed) return;

    try {
      _socket = await Socket.connect(roomInfo.address, roomInfo.port);
      _isSocketConnected = true;

      _socket.listen(
        _handleSocketData,
        onError: (error) => _handleConnectionError(error, isInitial: true),
        onDone: _handleSocketDone,
      );
    } catch (e) {
      _handleConnectionError(e, isInitial: true);
    }
  }

  void _handleSocketData(List<int> data) {
    if (_isDisposed) return;

    try {
      _recvBuffer += utf8.decode(data);

      _extractMessages();
    } catch (e) {
      _handleError("Failed to process socket data", e);
    }
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

      try {
        final message = NetworkMessage.fromString(jsonStr);
        _processNetworkMessage(message);
      } catch (e) {
        _handleError("Failed to parse network message", e);
      }

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

    if ((message.type == MessageType.accept) && (identify == 0)) {
      identify = message.id;
      sendNetworkMessage(MessageType.notify, "join in room");
    }

    if (message.type.index < MessageType.notify.index) {
      messageHandler(message);
    } else if (message.type.index >= MessageType.notify.index) {
      messageList.add(message);
    }
  }

  void _handleConnectionError(Object error, {bool isInitial = false}) {
    _isSocketConnected = false;
    _handleError("Connection error", error);

    if (isInitial) {
      // 初始连接失败处理
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
    } else {
      // 连接中断处理
      navigatorHandler.value = (context) {
        TemplateDialog.confirmDialog(
          context: context,
          title: "Connection lost",
          content: "The connection to the server has been lost",
          before: () => true,
          onTap: () {},
          after: () => leavePage(),
        );
      };
    }
  }

  void handleOpponentExit() {
    navigatorHandler.value = (context) {
      TemplateDialog.confirmDialog(
        context: context,
        title: "Competitors withdraw",
        content: "The opponent has withdrawn",
        before: () => true,
        onTap: () {},
        after: () {},
      );
    };
  }

  void _handleSocketDone() {
    if (_isDisposed) return;

    _isSocketConnected = false;
    _handleError("Socket connection closed", "Server disconnected");

    // 只有当不是主动调用leavePage导致的断开时才显示对话框
    if (!_isDisposed) {
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
  }

  void _startKeyboard() {
    if (_isDisposed) return;
    HardwareKeyboard.instance.addHandler(_handleChatKeyboardEvent);
  }

  void _stopKeyboard() {
    HardwareKeyboard.instance.removeHandler(_handleChatKeyboardEvent);
  }

  bool _handleChatKeyboardEvent(KeyEvent event) {
    if (_isDisposed) return false;

    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      sendInputText();
      return true;
    }
    return false;
  }

  void sendInputText() {
    if (_isDisposed) return;

    final text = textController.text.trim();
    if (text.isEmpty) return;

    sendNetworkMessage(MessageType.text, text);
    textController.clear();
  }

  void sendNetworkMessage(MessageType type, String content) {
    if (_isDisposed || identify == 0 || !_isSocketConnected) return;

    final message = NetworkMessage(
      id: identify,
      type: type,
      source: userName,
      content: content,
    );

    _sendBuffer.add(message);
    _processMessageQueue();
  }

  Future<void> _processMessageQueue() async {
    if (_isSending || _sendBuffer.isEmpty) return;

    _isSending = true;

    try {
      while (_sendBuffer.isNotEmpty && !_isDisposed) {
        final message = _sendBuffer.first;
        _socket.add(message.toSocketData());
        await _socket.flush(); // 确保数据发送
        _sendBuffer.removeAt(0);
      }
    } catch (e) {
      _handleError("Send network message failed", e);
    } finally {
      _isSending = false;
    }
  }

  void _handleError(String note, Object error) {
    debugPrint("$note: $error");
  }

  void leavePage() {
    if (_isDisposed) return;

    // 发送离开房间消息
    if (_isSocketConnected) {
      try {
        sendNetworkMessage(MessageType.exit, 'give up');
        sendNetworkMessage(MessageType.notify, 'leave room');
        // 给消息发送留出时间
        Future.delayed(const Duration(milliseconds: 200), _dispose);
      } catch (e) {
        _dispose();
      }
    } else {
      _dispose();
    }

    // 导航回上一页
    navigatorHandler.value = (BuildContext context) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    };
  }

  void _dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _isSocketConnected = false;

    try {
      _socket.destroy();
    } catch (_) {}

    _stopKeyboard();

    // // 释放资源
    // scrollController.dispose();
    // textController.dispose();
    // messageList.dispose();
  }
}
