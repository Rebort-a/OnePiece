import 'package:flutter/material.dart';

import '../00.common/widget/template_dialog.dart';
import '../00.common/network/network_room.dart';
import 'route.dart';

class RoomDialog {
  static void showCreateRoomDialog({
    required BuildContext context,
    required Function(String roomName, NetItemType roomType) onConfirm,
  }) {
    TemplateDialog.optionDialog<NetItemType>(
      context: context,
      title: 'Create',
      hintText: 'Enter room name',
      confirmButtonText: 'Create',
      options: NetItemType.values,
      onConfirm: onConfirm,
    );
  }

  static void showJoinRoomDialog({
    required BuildContext context,
    required RoomInfo room,
    required Function(String userName, RoomInfo room, BuildContext context)
    onConfirm,
  }) {
    TemplateDialog.inputDialog(
      context: context,
      title: 'Join',
      hintText: 'Enter user name',
      confirmButtonText: 'Join',
      onConfirm: (userName) => onConfirm(userName, room, context),
    );
  }

  static void showLeaveRoomDialog({
    required BuildContext context,
    required RoomInfo room,
    required Function() onConfirm,
  }) {
    TemplateDialog.confirmDialog(
      context: context,
      title: '离开',
      content: '即将退出房间',
      before: () => true,
      onTap: () {
        onConfirm();
      },
      after: () {},
    );
  }
}
