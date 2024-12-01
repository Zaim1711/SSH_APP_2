import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/model/chatRoom.dart';

class ChatRoomService {
  final String baseUrl =
      'http://10.0.2.2:8080/api/chatrooms'; // Ganti dengan URL API Anda

  Future<List<ChatRoom>> fetchChatRoomsBySender(String senderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/sender/$senderId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((chatRoom) => ChatRoom.fromJson(chatRoom))
          .toList();
    } else if (response.statusCode == 204) {
      return []; // Kembalikan daftar kosong jika tidak ada konten
    } else {
      throw Exception(
          'Failed to load chat rooms by sender: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<ChatRoom>> fetchChatRoomsByReceiver(String receiverId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/receiver/$receiverId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse
          .map((chatRoom) => ChatRoom.fromJson(chatRoom))
          .toList();
    } else if (response.statusCode == 204) {
      return []; // Kembalikan daftar kosong jika tidak ada konten
    } else {
      throw Exception(
          'Failed to load chat rooms by receiver: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<ChatRoom>> fetchAllChatRooms(String userId) async {
    // Ambil chat rooms berdasarkan senderId
    List<ChatRoom> senderRooms = await fetchChatRoomsBySender(userId);
    // Ambil chat rooms berdasarkan receiverId
    List<ChatRoom> receiverRooms = await fetchChatRoomsByReceiver(userId);

    // Gabungkan kedua daftar chat room
    return [...senderRooms, ...receiverRooms];
  }
}
