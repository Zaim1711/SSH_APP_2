import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/component/bottom_navigator.dart';
import 'package:ssh_aplication/model/userModel.dart';
import 'package:ssh_aplication/package/UserPage/ChatScreen.dart';
import 'package:ssh_aplication/package/UserPage/DasboardPage.dart';
import 'package:ssh_aplication/package/UserPage/PengaduanPage.dart';
import 'package:ssh_aplication/package/UserPage/ProfilePage.dart';
import 'package:ssh_aplication/services/ApiConfig.dart';

class Konsultanpage extends StatefulWidget {
  const Konsultanpage({Key? key}) : super(key: key);

  @override
  State<Konsultanpage> createState() => _KonsultanpageState();
}

class _KonsultanpageState extends State<Konsultanpage> {
  int _currentIndex = 2;
  List<User> konsultan = [];
  String userId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ambilDataKonsultan();
      decodeToken();
    });
  }

  Future<void> _ambilDataKonsultan() async {
    if (!mounted) return;

    try {
      final response = await http.get(Uri.parse(ApiConfig.fetchUser));
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          konsultan = jsonData
              .where((user) {
                final roles = user['roles'] as List;
                return roles.any((role) => role['name'] == 'ROLE_KONSULTAN');
              })
              .map((user) => User.fromJson(user))
              .toList(); // Convert to List<User>
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error: $e');
    }
  }

  Future<void> decodeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null) {
      Map<String, dynamic> payload = JwtDecoder.decode(accessToken);
      setState(() {
        userId = payload['sub'].split(',')[0];
      });
    } else {
      print("Token not found.");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      // Navigasi berdasarkan indeks yang dipilih
      switch (index) {
        case 0:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ProfilePage()));
          break;
        case 1:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => DasboardPage()));
          break;
        case 2:
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => MultiPageForm()));
          break;
      }
    });
  }

  Widget _buildKonsultanList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (konsultan.isEmpty) {
      return const Center(child: Text('Tidak ada konsultan yang tersedia'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: konsultan.length,
      itemBuilder: (context, index) {
        User selectedUser = konsultan[index];
        return KonsultanCard(
          konsultan: selectedUser,
          senderId: userId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Daftar Konsultan',
            style: TextStyle(
                color: Color(0xFF0E197E),
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: _buildKonsultanList(),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class KonsultanCard extends StatelessWidget {
  final User konsultan;
  final String senderId;

  KonsultanCard({
    Key? key,
    required this.konsultan,
    required this.senderId,
  }) : super(key: key);

  void navigateToChatScreen(BuildContext context, User user, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chatscreen(
          user: konsultan,
          senderId: userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    konsultan.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        konsultan.username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        konsultan.email,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  navigateToChatScreen(context, konsultan, senderId);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Hubungi Konsultan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
