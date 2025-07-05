import 'dart:async';
import 'dart:io';

const String multicastAddress = '224.0.0.251';
const int multicastPort = 4545;
const String broadcastNetmask = '255.255.255.0';

// 负责发送广播和组播消息
class Broadcast {
  static Future<RawDatagramSocket> initSocket() async {
    RawDatagramSocket socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0, // 使用临时端口
      reuseAddress: true,
      ttl: 255,
    );
    // 开启广播支持
    socket.broadcastEnabled = true;
    return socket;
  }

  // 发送单条消息
  static Future<void> sendMessage(List<int> data) async {
    RawDatagramSocket sendSocket = await initSocket();

    // 发送组播
    sendSocket.send(data, InternetAddress(multicastAddress), multicastPort);

    // 发送广播
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    // 遍历网卡
    for (final interface in interfaces) {
      // 遍历ip
      for (final address in interface.addresses) {
        // 如果是IPv4地址
        if (isIPv4(address.address)) {
          final broadcast = _getBroadcastAddress(
            address.address,
            broadcastNetmask,
          );
          sendSocket.send(data, InternetAddress(broadcast), multicastPort);
        }
      }
    }

    sendSocket.close();
  }

  // --- 静态工具方法 ---
  // 判断是否为IPv4地址，来源getX
  static bool isIPv4(String address) {
    return RegExp(
      r'^(?:(?:^|\.)(?:2(?:5[0-5]|[0-4]\d)|1?\d?\d)){4}$',
    ).hasMatch(address);
  }

  // 使用ip地址和子网掩码组合获取广播地址
  static String _getBroadcastAddress(String localAddress, String netmask) {
    final localParts = localAddress.split('.').map(int.parse).toList();
    final netmaskParts = netmask.split('.').map(int.parse).toList();

    return List.generate(4, (i) {
      return (localParts[i] | (~netmaskParts[i] & 0xFF)).toString();
    }).join('.');
  }
}

// 负责接收广播和组播消息
class Discovery {
  static Future<RawDatagramSocket> initSocket() async {
    RawDatagramSocket socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      multicastPort,
      reuseAddress: true,
      ttl: 255,
    );

    // 开启广播支持
    socket.broadcastEnabled = true;
    socket.readEventsEnabled = true;

    // 接收组播消息
    socket.joinMulticast(InternetAddress(multicastAddress));

    return socket;
  }

  // 开始监听消息
  void startReceive(
    void Function(String address, List<int> data) callback,
  ) async {
    RawDatagramSocket socket = await initSocket();

    // 监听消息事件
    socket.listen((RawSocketEvent event) async {
      if (event == RawSocketEvent.read) {
        final dgram = socket.receive();
        if (dgram != null) {
          callback(dgram.address.address, dgram.data);
        }
      }
    });
  }
}
