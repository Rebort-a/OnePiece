import 'dart:convert';

enum MessageType {
  // 系统信息
  broadcast,
  accept,

  // 游戏信息
  search,
  match,
  resource,
  sync,
  action,
  exit,

  // 聊天信息
  notify,
  text,
  image,
  file,
}

class NetworkMessage {
  int id;
  MessageType type;
  String source;
  String content;

  NetworkMessage({
    required this.id,
    required this.type,
    required this.source,
    required this.content,
  });

  factory NetworkMessage.fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      id: json['id'],
      type: MessageType.values[json['type']],
      source: json['source'],
      content: json['content'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type.index, 'source': source, 'content': content};
  }

  factory NetworkMessage.fromJsonString(String data) {
    return NetworkMessage.fromJson(jsonDecode(data));
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory NetworkMessage.fromSocketData(List<int> data) {
    return NetworkMessage.fromJsonString(utf8.decode(data));
  }

  List<int> toSocketData() {
    return utf8.encode(toJsonString());
  }
}
