import 'dart:convert';

enum RoomState { start, stop }

class RoomInfo {
  final String name;
  final int type;
  final String address;
  final int port;

  RoomInfo({
    required this.name,
    required this.type,
    required this.address,
    required this.port,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type, 'address': address, 'port': port};
  }

  static String getNameFromJson(Map<String, dynamic> json) {
    return json['name'];
  }

  static int getTypeFromJson(Map<String, dynamic> json) {
    return json['type'];
  }

  static String getAddressFromJson(Map<String, dynamic> json) {
    return json['address'];
  }

  static int getPortFromJson(Map<String, dynamic> json) {
    return json['port'];
  }

  factory RoomInfo.fromJson(Map<String, dynamic> json) {
    return RoomInfo(
      name: getNameFromJson(json),
      type: getTypeFromJson(json),
      address: getAddressFromJson(json),
      port: getPortFromJson(json),
    );
  }

  static RoomState getOperationFromJson(Map<String, dynamic> json) {
    return RoomState.values[json['operation']];
  }

  static Map<String, dynamic> configToJson(
    int port,
    int type,
    RoomState operation,
  ) {
    return {'port': port, 'type': type, 'operation': operation.index};
  }

  static String configToJsonString(int port, int type, RoomState operation) {
    return jsonEncode(configToJson(port, type, operation));
  }

  static RoomState getOperationFromJsonString(String data) {
    return getOperationFromJson(jsonDecode(data));
  }

  static int getPortFromJsonString(String data) {
    return getPortFromJson(jsonDecode(data));
  }

  static int getTypeFromJsonString(String data) {
    return getTypeFromJson(jsonDecode(data));
  }
}
