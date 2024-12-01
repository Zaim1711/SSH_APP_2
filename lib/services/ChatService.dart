import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  final WebSocketChannel channel;

  ChatService(String chatRoomId)
      : channel = WebSocketChannel.connect(
          Uri.parse('ws://10.0.2.2:8080/topic/ws/$chatRoomId'),
        );

  void sendMessage(String message, String chatRoomId, String senderId) {
    final messageDto = {
      'chatRoomId': chatRoomId,
      'messageContent': message,
      'senderId': senderId,
    };
    channel.sink.add(json.encode(messageDto));
  }

  Stream<dynamic> get messages => channel.stream;

  void dispose() {
    channel.sink.close();
  }
}
