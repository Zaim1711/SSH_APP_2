import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/component/bottom_navigator.dart';
import 'package:ssh_aplication/package/EventDetailPage.dart';
import 'package:ssh_aplication/package/LandingPageChat.dart';
import 'package:ssh_aplication/package/PengaduanPage.dart';
import 'package:ssh_aplication/package/ProfilePage.dart';
import 'package:ssh_aplication/services/LocationService.dart';
import 'package:ssh_aplication/services/NotificatioonService.dart';
import 'package:ssh_aplication/services/WebSocketConfig.dart';

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
  late WebSocketService webSocketService;
  late LocationService locationService;

  @override
  void initState() {
    super.initState();
    decodeToken();
    notificationService.requestNotificationPermission();
    _requestLocationPermission();
    notificationService.init();
    notificationService.configureFCM();
    notificationService.getDeviceToken().then((value) {
      print('device token');
    });
    webSocketService = WebSocketService();
    locationService = LocationService(webSocketService);
  }

  @override
  void dispose() {
    locationService.stopSendingLocation();
    webSocketService.close();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted.");
    } else if (status.isDenied) {
      print("Location permission denied.");
    } else if (status.isPermanentlyDenied) {
      print("Location permission permanently denied.");
      // Mungkin arahkan pengguna ke pengaturan aplikasi untuk mengaktifkan izin.
    }
  }

  Future<void> decodeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null) {
      payload = JwtDecoder.decode(accessToken);
      String name = payload['sub'].split(',')[2];
      String id = payload['sub'].split(',')[0];
      // Mengambil nilai 'name' dari token JWT
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
      Uri.parse('http://10.0.2.2:8080/pengaduan/user/$userId'),
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
    final imageUrl =
        'http://10.0.2.2:8080/pengaduan/image/$imageName'; // URL gambar
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
    // Memecah nama berdasarkan spasi
    List<String> nameParts = name.split(' ');

    // Mengambil dua nama pertama jika ada lebih dari dua
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
          MaterialPageRoute(
              builder: (context) =>
                  DasboardPage()), // Pastikan ini adalah logika navigasi yang benar
        );
      }

      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ProfilePage()), // Pastikan ini adalah logika navigasi yang benar
        );
      }
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MultiPageForm()), // Pastikan ini adalah logika navigasi yang benar
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
            // Bagian atas tampilan
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
                    'Hi $userName', // Menggunakan variabel userName
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

            // Kontainer "Welcome!" dengan gambar dan teks
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

            // Teks "Ongoing Event"
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
                // Daftar History Laporan
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
                            future: fetchImage(
                                laporan['bukti_kekerasan']), // Ambil gambar
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
                                return Icon(Icons
                                    .image_not_supported); // Menampilkan ikon jika gambar tidak ditemukan
                              } else {
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
                            },
                          ),
                        ),
                        Positioned(
                          left: 278,
                          top: 63,
                          child: Text(
                            '${laporan['status']}',
                            style: TextStyle(
                              color:
                                  statusColor, // Menggunakan warna yang ditentukan
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
            ElevatedButton(
              onPressed: () {
                locationService.startSendingLocation();
              },
              child: Text('Start Tracking'),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    ));
  }
}
