import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/component/bottom_navigator.dart'; // Make sure to import the correct path
import 'package:ssh_aplication/component/logout_button.dart';
import 'package:ssh_aplication/package/DasboardPage.dart';
import 'package:ssh_aplication/package/LoginPage.dart';
import 'package:ssh_aplication/package/TestMultiPage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 1;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, dynamic> payload = {};
  String userId = '';
  String emailUser = ''; // Deklarasi variabel email
  String nameUser = '';
  File? _selectedImage; // Deklarasi variabel nameUser
  // Deklarasi variabel nameUser

  @override
  void initState() {
    super.initState();
    decodeToken();
  }

  Future<void> _deleteFcmToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null) {
      // Call the API to delete the FCM token
      String url =
          'http://10.0.2.2:8080/api/tokens/$userId'; // Adjust the URL as needed
      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $accessToken';

      try {
        await dio.delete(url);
        print('FCM token deleted successfully');
      } catch (e) {
        print('Error deleting FCM token: $e');
      }
    }
  }

  bool isPickingImage = false; // Menandakan apakah sedang mengambil gambar

  Future<void> _pickImage() async {
    if (isPickingImage) return; // Jangan jalankan jika masih aktif

    isPickingImage = true; // Menandakan proses sudah dimulai
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });
      }
    } catch (e) {
      // Tangani kesalahan jika perlu
      print('Error picking image: $e');
    } finally {
      isPickingImage = false; // Mengaktifkan kembali setelah selesai
    }
  }

  File? savedImage;

  Future<String> saveImageToDirectory(File imageFile) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String imagePath =
        '${directory.path}/image_form/${DateTime.now().millisecondsSinceEpoch}.png';

    // Buat direktori jika belum ada
    await Directory('${directory.path}/image_form/').create(recursive: true);

    File savedImage = await imageFile.copy(imagePath);
    return savedImage.path;
  }

  Future<void> decodeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null) {
      payload = JwtDecoder.decode(accessToken);
      String id = payload['sub'].split(',')[0];
      // Mengambil nilai 'id' dari token JWT
      setState(() {
        userId = id;
      });

      await fetchData(id);
    }
  }

  Future<void> fetchData(String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accesToken');

      if (accessToken == null) {
        print('Access token not found');
        return;
      }

      // Ganti URL dengan endpoint backend Anda dan tambahkan ID ke URL
      String url = 'http://10.0.2.2:8080/users/$id';

      Dio dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $accessToken';

      Response response = await dio.get(url);

      Map<String, dynamic> userData = response.data;
      setState(() {
        // Respons berisi data user
        emailUser = userData['email'];
        nameUser = userData['username'];
      });
    } catch (error) {
      print('Error fetching data from backend: $error');
    }
  }

  // Fungsi untuk menghapus token dan data lainnya
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('accesToken'); // Hapus token akses
    // Hapus data pengguna lainnya jika perlu
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProfilePage()), // Make sure this is the correct navigation logic
        );
      }
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  DasboardPage()), // Make sure this is the correct navigation logic
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
    // Implement your profile page UI here
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // Bagian atas tampilan
              Container(
                padding: const EdgeInsets.all(5.0),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image(
                      image: AssetImage('lib/image/Logo.png'),
                      width: 100,
                      height: 40,
                    ),
                  ],
                ),
              ),
              Container(
                width: 360,
                height: 366,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 55,
                      child: Container(
                        width: 360,
                        height: 251,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF0E197E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(4, 4),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(-4, -4),
                              spreadRadius: 0,
                            )
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left:
                          115, // Sesuaikan posisi horizontal sesuai kebutuhan Anda
                      top: 70,
                      child: Form(
                        key:
                            _formKey, // Sesuaikan posisi vertikal sesuai kebutuhan Anda
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            InkWell(
                              onTap: _pickImage,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF4F4F4),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: _selectedImage == null
                                    ? Icon(Icons.add_a_photo)
                                    : ClipOval(
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 130,
                                          height: 130,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(
                                height:
                                    16), // Tambahkan jarak antara widget di atas dengan widget Text
                            Text(
                              "$nameUser",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // Anda perlu menambahkan widget lain ke dalam Column sesuai kebutuhan Anda
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 17,
                      top: 262,
                      child: Container(
                        width: 326,
                        height: 104,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, -2),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(2, 0),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(-2, 0),
                              spreadRadius: 0,
                            )
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 62,
                      top: 283,
                      child: Text(
                        'My Address',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 62,
                      top: 331,
                      child: Text(
                        'Account',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                width: 325,
                height: 240,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: 325,
                        height: 240,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(-2, 0),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                            )
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 44,
                      top: 24,
                      child: Text(
                        'Comunnity',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 44,
                      top: 86,
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 44,
                      top: 139,
                      child: Text(
                        'History',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 44,
                      top: 199,
                      child: Text(
                        'About us',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              MyButtonLogout(
                onTap: () async {
                  await _deleteFcmToken(); // Hapus token FCM jika perlu
                  await _logout(); // Panggil fungsi logout
                  _navigateToLogOut(context); // Navigasi ke halaman login
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

void _navigateToLogOut(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: animation,
        child: LoginPage(),
      ),
    ),
    (Route<dynamic> route) => false, // Hapus semua route sebelumnya
  );
}
