import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/model/userModel.dart';
import 'package:ssh_aplication/package/ChatScreen.dart';
import 'package:ssh_aplication/services/ApiConfig.dart';
import 'package:ssh_aplication/services/UserService.dart' as user_service;

class UserService {
  Future<List<User>> fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken == null) {
      throw Exception('Access token not found');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.saveUser),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((user) => User.fromJson(user)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }
}

class UserListChat extends StatefulWidget {
  @override
  _UserListChatState createState() => _UserListChatState();
}

class _UserListChatState extends State<UserListChat> {
  late Future<List<User>> futureUsers;
  String userEmail = '';
  String userId = '';

  @override
  void initState() {
    super.initState();
    futureUsers = UserService().fetchUsers();
    decodeToken();
  }

  Future<void> decodeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null) {
      Map<String, dynamic> payload = JwtDecoder.decode(accessToken);
      setState(() {
        userEmail = payload['sub'].split(',')[1];
        userId = payload['sub'].split(',')[0];
      });
    } else {
      print("Token not found.");
    }
  }

  void showNotification(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> createRoom(User user, String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken == null) {
      print('Access token is null');
      showNotification('Access token not found');
      return;
    }

    final url = Uri.parse(ApiConfig.createRoom);
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'senderId': userId,
          'receiverId': user.id,
        }));

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      int roomId = data['id'];
      navigateToChatScreen(roomId.toString(), user.id.toString(), userId);
    } else {
      if (response.statusCode == 409) {
        showNotification('Chat sudah ada.');
      } else {
        print('An error occurred: ${response.body}');
      }
    }
  }

  void navigateToChatScreen(
      String roomId, String receiverId, String userId) async {
    try {
      User user = await user_service.UserService().fetchUser(receiverId);
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Chatscreen(
              user: user,
              roomId: roomId,
              senderId: userId,
            ),
          ),
        );
      } else {
        showNotification('Gagal mengambil detail pengguna.');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const String defaultProfileImagePath = 'lib/image/image.png';

    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Pengguna'),
      ),
      body: FutureBuilder<List<User>>(
        future: futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Tidak ada pengguna ditemukan.'));
          }

          List<User> users = snapshot.data!
              .where((user) =>
                  user.email !=
                  userEmail) // Filter out the logged-in user by email
              .where((user) => user.roles.any((role) =>
                  role.name ==
                  'ROLE_KONSULTAN')) // Filter users with ROLE_PSYCOLOGIST
              .toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: users[index].profileImage.isNotEmpty
                      ? NetworkImage(users[index].profileImage)
                      : AssetImage(defaultProfileImagePath) as ImageProvider,
                ),
                title: Text(users[index].email),
                onTap: () => createRoom(users[index], userId),
              );
            },
          );
        },
      ),
    );
  }
}
