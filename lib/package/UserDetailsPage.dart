import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/component/bottom_navigator.dart';
import 'package:ssh_aplication/model/DetailsUser.dart';
import 'package:ssh_aplication/package/DasboardPage.dart';
import 'package:ssh_aplication/package/EditProfilePage.dart';
import 'package:ssh_aplication/package/PengaduanPage.dart';
import 'package:ssh_aplication/package/ProfilePage.dart';
import 'package:ssh_aplication/services/ApiConfig.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  int _currentIndex = 1;

  Future<DetailsUser?> fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken == null) {
      throw Exception('Access token is null');
    }

    Map<String, dynamic> payload = JwtDecoder.decode(accessToken);
    String userId = payload['sub'].split(',')[0];

    final response = await http.get(
      Uri.parse(ApiConfig.getcheckUserUrl(userId)),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      try {
        final jsonResponse = json.decode(response.body);
        return DetailsUser.fromJson(jsonResponse);
      } catch (e) {
        throw Exception('Failed to parse user details');
      }
    } else {
      throw Exception('Failed to load user details: ${response.statusCode}');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  DasboardPage()), // Make sure this is the correct navigation logic
        );
      }

      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProfilePage()), // Make sure this is the correct navigation logic
        );
      }
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MultiPageForm()), // Make sure this is the correct navigation logic
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 150,
            decoration: ShapeDecoration(
              color: const Color(0xFFF4F4F4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image(
                  image: AssetImage('lib/image/Logo.png'),
                  width: 100,
                  height: 80,
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Profile",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D187E),
                    ),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<DetailsUser?>(
              future: fetchUserDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        Text('Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData) {
                  return const Center(
                    child: Text('User  not found',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                  );
                }

                DetailsUser userDetail = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person,
                                      color: Color(0xFF0E197E), size: 40),
                                  const SizedBox(width: 10),
                                  Text(
                                    'User  Details',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, thickness: 1),
                              ListTile(
                                leading: const Icon(Icons.badge,
                                    color: Color(0xFF0E197E)),
                                title: const Text('NIK'),
                                subtitle: Text(userDetail.nik,
                                    style: const TextStyle(fontSize: 16)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.home,
                                    color: Color(0xFF0E197E)),
                                title: const Text('Alamat'),
                                subtitle: Text(userDetail.alamat,
                                    style: const TextStyle(fontSize: 16)),
                              ),
                              ListTile(
                                leading: const Icon(Icons.phone,
                                    color: Color(0xFF0E197E)),
                                title: const Text('Nomor Telepon'),
                                subtitle: Text(userDetail.nomorTelepon,
                                    style: const TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final bool? isUpdated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfilePage(userDetail: userDetail),
                            ),
                          );

                          if (isUpdated == true) {
                            setState(() {
                              fetchUserDetails();
                            });
                          }
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Edit Profile',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                          backgroundColor: const Color(0xFF0E197E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
