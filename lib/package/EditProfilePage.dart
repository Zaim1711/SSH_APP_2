import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ssh_aplication/model/DetailsUser.dart';

class EditProfilePage extends StatefulWidget {
  final DetailsUser userDetail;
  const EditProfilePage({Key? key, required this.userDetail}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _nomorTeleponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Isi controller dengan data yang ada
    _nikController.text = widget.userDetail.nik ?? '';
    _alamatController.text = widget.userDetail.alamat ?? '';
    _nomorTeleponController.text = widget.userDetail.nomorTelepon ?? '';
  }

  @override
  void dispose() {
    _nikController.dispose();
    _alamatController.dispose();
    _nomorTeleponController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final String nik = _nikController.text;
    final String alamat = _alamatController.text;
    final String nomorTelepon = _nomorTeleponController.text;
    final String id = widget.userDetail.id.toString();

    // ID pengguna bisa didapatkan dari argumen atau penyimpanan lokal
    String userId = id; // Ganti dengan ID pengguna yang sebenarnya
    const String baseUrl = "http://10.0.2.2:8080/details"; // URL backend

    try {
      // Kirim data ke server
      final response = await http.put(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nik': nik,
          'alamat': alamat,
          'nomor_telepon': nomorTelepon,
        }),
      );

      // Periksa respons
      if (response.statusCode == 200) {
        print('Profile updated successfully');
        // Tampilkan pesan sukses (opsional)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, true); // Kembali ke halaman sebelumnya
      } else {
        print('Failed to update profile: ${response.statusCode}');
        // Tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      print('Error: $e');
      // Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E197E),
        iconTheme:
            const IconThemeData(color: Colors.white), // Set icon color to white
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
                backgroundColor: Color(0xFF0E197E),
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
    );
  }
}