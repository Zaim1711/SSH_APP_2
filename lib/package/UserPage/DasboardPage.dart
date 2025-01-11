import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/component/bottom_navigator.dart';
import 'package:ssh_aplication/package/UserPage/EmergencyPage.dart';
import 'package:ssh_aplication/package/UserPage/EventDetailPage.dart';
import 'package:ssh_aplication/package/UserPage/KonsultanPage.dart';
import 'package:ssh_aplication/package/UserPage/LandingPageChat.dart';
import 'package:ssh_aplication/package/UserPage/PengaduanPage.dart';
import 'package:ssh_aplication/package/UserPage/ProfilePage.dart';
import 'package:ssh_aplication/package/UserPage/TestInfromasiPage.dart';
import 'package:ssh_aplication/services/ApiConfig.dart';
import 'package:ssh_aplication/services/NotificatioonService.dart';
import 'package:video_player/video_player.dart';

class DasboardPage extends StatefulWidget {
  @override
  _DasboardPageState createState() => _DasboardPageState();
}

class _DasboardPageState extends State<DasboardPage> {
  int _currentIndex = 2; // Indeks halaman yang dipilih
  List<dynamic> ongoingEvents = [];
  Map<String, dynamic> payload = {};
  String userName = '';
  String userId = '';
  NotificationService notificationService = NotificationService();
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    decodeToken();
    notificationService.requestNotificationPermission();
    notificationService.init();
    notificationService.configureFCM();
    notificationService.getDeviceToken().then((value) {
      print('device token');
    });
  }

  @override
  void dispose() {
    _videoController?.dispose(); // Membersihkan controller video
    super.dispose();
  }

  Future<void> decodeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null) {
      payload = JwtDecoder.decode(accessToken);
      String name = payload['sub'].split(',')[2];
      String id = payload['sub'].split(',')[0];
      setState(() {
        userName = name;
        userId = id;
      });

      // Panggil _loadDataLaporan dengan userId dan accessToken
      _loadDataLaporan(id, accessToken);
    }
  }

  void _loadDataLaporan(String userId, String accessToken) async {
    final response = await http.get(
      Uri.parse(ApiConfig.fetchPengaduanById(userId)),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        ongoingEvents = json.decode(response.body);
      });
    } else {
      print('Gagal mengambil data laporan : ${response.statusCode}');
    }
  }

  Future<Uint8List?> fetchImage(String imageName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');
    final imageUrl = ApiConfig.getFetchImage(imageName); // URL gambar
    final response = await http.get(
      Uri.parse(imageUrl),
      headers: {
        'Authorization':
            'Bearer $accessToken', // Menambahkan token JWT ke header
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes; // Mengembalikan byte gambar
    } else {
      print('Gagal mengambil gambar: ${response.statusCode}'); // Debugging
      return null; // Mengembalikan null jika gagal
    }
  }

  String _getFormattedName(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 2) {
      return '${nameParts[0]} ${nameParts[1]}'; // Mengembalikan dua nama pertama
    } else {
      return name; // Mengembalikan nama aslinya jika kurang dari atau sama dengan dua
    }
  }

  String formatIsoDateToNormal(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    return formatter.format(dateTime);
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DasboardPage()),
        );
      }

      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      }
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MultiPageForm()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(5.0),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image(
                    image: AssetImage('lib/image/Logo.png'),
                    width: 100,
                    height: 80,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 250, top: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi $userName',
                    style: const TextStyle(
                      color: Color(0xFF0E197E),
                      fontSize: 24,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: Color(0xFF0E197E),
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 320, bottom: 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LandingPageChatRooms(),
                        ),
                      );
                    },
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.message,
                          color: Color(0xFF0E197E),
                          size: 30,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 350,
              height: 112,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 350,
                      height: 112,
                      decoration: ShapeDecoration(
                        color: const Color(0x00D9D9D9),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                              width: 2, color: Color(0xFF0E197E)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 32,
                    top: 24,
                    child: Text(
                      'Welcome!',
                      style: TextStyle(
                        color: Color(0xFF0E197E),
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 32,
                    top: 49,
                    child: Text(
                      'We Care About\nYou',
                      style: TextStyle(
                        color: Color(0x990E197E),
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 156,
                    top: 3,
                    child: Container(
                      width: 164,
                      height: 107,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('lib/image/greething_dasboard.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 15, left: 15),
                      child: const Text(
                        'History Pengaduan',
                        style: TextStyle(
                          color: Color(0xFF0E197E),
                          fontSize: 18,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Column(
              children: ongoingEvents.map((laporan) {
                Color statusColor;
                // Menentukan warna berdasarkan status
                if (laporan['status'] == 'Validation') {
                  statusColor = Color(0xFF0E197E); // Biru untuk pending
                } else if (laporan['status'] == 'Approved') {
                  statusColor = Colors.green; // Hijau untuk approved
                } else if (laporan['status'] == 'Rejected') {
                  statusColor = Colors.red; // Merah untuk rejected
                } else {
                  statusColor =
                      Colors.grey; // Warna default jika status tidak diketahui
                }
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailPage(
                          laporan: laporan,
                          imagePath: laporan['bukti_kekerasan'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    width: 342,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        )
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 93,
                          top: 50,
                          child: Text(
                            formatIsoDateToNormal(
                                '${laporan['tanggal_kekerasan']}'),
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.47),
                              fontSize: 10,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 93,
                          top: 11,
                          child: SizedBox(
                            width: 249,
                            child: Text(
                              _getFormattedName(laporan['name']) +
                                  '\n' +
                                  laporan['status_pelapor'] +
                                  ' ' +
                                  laporan['jenis_kekerasan'],
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 7,
                          top: 6,
                          child: FutureBuilder<Uint8List?>(
                            future: fetchImage(laporan['bukti_kekerasan']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  width: 71,
                                  height: 71,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              } else if (snapshot.hasError ||
                                  snapshot.data == null) {
                                return Icon(Icons.image_not_supported);
                              } else {
                                // Cek apakah bukti_kekerasan adalah video
                                if (laporan['bukti_kekerasan']
                                    .endsWith('.mp4')) {
                                  // Jika video, tampilkan ikon video
                                  return Container(
                                    width: 71,
                                    height: 71,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors
                                          .grey[300], // Warna latar belakang
                                    ),
                                    child: Icon(
                                      Icons.videocam,
                                      color: Colors.black,
                                      size: 50,
                                    ),
                                  );
                                } else {
                                  // Jika gambar, tampilkan gambar
                                  return Container(
                                    width: 71,
                                    height: 71,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.memory(snapshot.data!,
                                        fit: BoxFit.cover),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        Positioned(
                          left: 278,
                          top: 63,
                          child: Text(
                            '${laporan['status']}',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            Container(
              width: 350,
              height: 350,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blueAccent, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kami memahami bahwa berbicara tentang pengalaman kekerasan seksual bisa sangat sulit dan menyakitkan. Jika Anda atau seseorang yang Anda kenal telah mengalami kekerasan seksual, kami ingin Anda tahu bahwa Anda tidak sendirian. Kami di sini untuk mendengarkan dan memberikan dukungan yang Anda butuhkan.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Mengatur posisi tombol
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Konsultanpage()),
                            );
                          },
                          child: const Text('Konsultasi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // Jarak antara tombol
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => InformationPage()),
                            );
                          },
                          child: const Text('Informasi Hukum'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EmergencyPage()),
          );
        },
        label: Icon(
          Icons.sos,
          size: 30,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    ));
  }
}
