import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/package/DasboardPage.dart';
import 'package:ssh_aplication/package/UserDetailsPage.dart';
import 'package:ssh_aplication/services/ApiConfig.dart'; // Pastikan Anda mengimpor DashboardPage

class InputUserDetails extends StatefulWidget {
  const InputUserDetails({Key? key}) : super(key: key);

  @override
  State<InputUserDetails> createState() => _InputUserDetailsState();
}

class _InputUserDetailsState extends State<InputUserDetails> {
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _nomorTeleponController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nikController.dispose();
    _alamatController.dispose();
    _nomorTeleponController.dispose();
    super.dispose();
  }

  Future<bool> _checkUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken == null) {
      return false; // Token tidak ada
    }

    Map<String, dynamic> payload = JwtDecoder.decode(accessToken);
    String userId = payload['sub'].split(',')[0];

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getdetailsUser(userId)),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        var userDetails = jsonDecode(response.body);
        return userDetails.isNotEmpty; // Kembalikan true jika data ada
      } else {
        return false; // Data tidak ditemukan
      }
    } catch (e) {
      print('Error: $e');
      return false; // Jika terjadi kesalahan
    }
  }

  void _saveProfile() async {
    final String nik = _nikController.text;
    final String alamat = _alamatController.text;
    final String nomorTelepon = _nomorTeleponController.text;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken == null) {
      throw Exception('Access token is null');
    }

    Map<String, dynamic> payload = JwtDecoder.decode(accessToken);
    String userId = payload['sub'].split(',')[0];

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.detailsUser),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nik': nik,
          'alamat': alamat,
          'nomor_telepon': nomorTelepon,
          'userId': userId,
        }),
      );

      if (response.statusCode == 201) {
        print('Profile Berhasil disimpan');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Berhasil Disimpan')),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    UserDetailsPage())); // Kembali ke halaman sebelumnya
      } else {
        print('Failed to update profile: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  Future<bool> _onWillPop() async {
    bool hasUserDetails = await _checkUserDetails();
    if (!hasUserDetails) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DasboardPage()),
      );
      return false; // Mencegah navigasi kembali ke halaman sebelumnya
    }
    return true; // Izinkan navigasi kembali jika data ada
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detail Pengguna',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0E197E),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nikController,
                decoration: const InputDecoration(
                  labelText: 'NIK',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nomorTeleponController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: const Color(0xFF0E197E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
