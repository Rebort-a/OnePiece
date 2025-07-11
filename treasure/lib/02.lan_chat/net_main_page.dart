import 'package:flutter/material.dart';

import '../00.common/network/network_room.dart';
import '../00.common/widget/chat_component.dart';
import '../00.common/widget/notifier_navigator.dart';
import 'net_chat_manager.dart';

class NetChatPage extends StatelessWidget {
  late final NetChatManager _chatManager;
  final String userName;
  final RoomInfo roomInfo;

  NetChatPage({super.key, required this.userName, required this.roomInfo}) {
    _chatManager = NetChatManager(userName: userName, roomInfo: roomInfo);
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: _buildAppBar(), body: _buildBody());

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(roomInfo.name),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _chatManager.networkEngine.leavePage,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.video_call),
          onPressed: () {}, // Placeholder for video call
        ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {}, // Placeholder for audio call
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        NotifierNavigator(navigatorHandler: _chatManager.pageNavigator),
        Expanded(child: MessageList(networkEngine: _chatManager.networkEngine)),
        MessageInput(networkEngine: _chatManager.networkEngine),
      ],
    );
  }
}
