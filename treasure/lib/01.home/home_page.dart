import 'package:flutter/material.dart';

import '../00.common/network/network_room.dart';
import '../00.common/style/theme.dart';
import '../00.common/component/notifier_navigator.dart';
import 'home_manager.dart';
import 'route.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _homeManager = HomeManager();

  // 列表展开状态管理
  bool _localExpanded = true;
  bool _createdExpanded = true;
  bool _othersExpanded = true;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: _buildAppBar(), body: _buildBody());

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('room list'),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _homeManager.showCreateRoomDialog,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return ListView(
      children: [
        NotifierNavigator(navigatorHandler: _homeManager.pageNavigator),
        _buildLocalSection(),
        _buildCreatedRoomsSection(),
        _buildOthersRoomsSection(),
      ],
    );
  }

  Widget _buildLocalSection() {
    return Column(
      children: [
        ListTile(
          leading: ExpandIcon(
            isExpanded: _localExpanded,
            onPressed: (bool isExpanded) {
              setState(() => _localExpanded = !isExpanded);
            },
          ),
          title: Text('Local', style: globalTheme.textTheme.titleLarge),
        ),
        if (_localExpanded)
          ...LocalItemType.values.map((type) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.gamepad),
                title: Text(type.toString().split('.').last),
                onTap: () => _homeManager.routeLocal(type),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCreatedRoomsSection() {
    return ValueListenableBuilder<List<CreatedRoomInfo>>(
      valueListenable: _homeManager.createdRooms,
      builder: (context, rooms, child) {
        if (rooms.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            ListTile(
              leading: ExpandIcon(
                isExpanded: _createdExpanded,
                onPressed: (bool isExpanded) {
                  setState(() => _createdExpanded = !isExpanded);
                },
              ),
              title: Text(
                'The rooms you created',
                style: globalTheme.textTheme.titleLarge,
              ),
              trailing: rooms.length > 1
                  ? TextButton(
                      onPressed: _homeManager.stopAllCreatedRooms,
                      child: const Text('STOP ALL'),
                    )
                  : null,
            ),
            if (_createdExpanded)
              ...rooms.asMap().entries.map((entry) {
                final index = entry.key;
                final room = entry.value;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.home),
                    title: Text(
                      "${room.name} ${NetItemType.values[room.type].toString().split('.').last}",
                    ),
                    subtitle: Text('${room.address}:${room.port}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _homeManager.showJoinRoomDialog(room),
                          child: const Text('JOIN'),
                        ),
                        TextButton(
                          onPressed: () => _homeManager.stopCreatedRoom(index),
                          child: const Text('STOP'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildOthersRoomsSection() {
    return ValueListenableBuilder<List<RoomInfo>>(
      valueListenable: _homeManager.othersRooms,
      builder: (context, rooms, child) {
        if (rooms.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            ListTile(
              leading: ExpandIcon(
                isExpanded: _othersExpanded,
                onPressed: (bool isExpanded) {
                  setState(() => _othersExpanded = !isExpanded);
                },
              ),
              title: Text(
                'The other rooms',
                style: globalTheme.textTheme.titleLarge,
              ),
            ),
            if (_othersExpanded)
              ...rooms.map((room) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.home),
                    title: Text(
                      "${room.name} ${NetItemType.values[room.type].toString().split('.').last}",
                    ),
                    subtitle: Text('${room.address}:${room.port}'),
                    trailing: TextButton(
                      onPressed: () => _homeManager.showJoinRoomDialog(room),
                      child: const Text('JOIN'),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
