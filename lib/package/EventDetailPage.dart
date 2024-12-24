import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ssh_aplication/component/bottom_navigator.dart';
import 'package:ssh_aplication/package/DasboardPage.dart';
import 'package:ssh_aplication/package/PengaduanPage.dart';
import 'package:ssh_aplication/package/ProfilePage.dart';
import 'package:ssh_aplication/package/TestInfromasiPage.dart';
import 'package:ssh_aplication/package/UserListChat.dart';
import 'package:ssh_aplication/services/ApiConfig.dart';

class EventDetailPage extends StatefulWidget {
  final Map<String, dynamic> laporan;
  final String imagePath;

  EventDetailPage({required this.laporan, required this.imagePath});

  @override
  _EventDetailPageState createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  int _currentIndex = 2;

  String formatIsoDateToNormal(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    final DateFormat formatter = DateFormat('dd MMMM yyyy', 'id_ID');
    return formatter.format(dateTime);
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      // Navigasi berdasarkan indeks yang dipilih
      switch (index) {
        case 1:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ProfilePage()));
          break;
        case 2:
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => DasboardPage()));
          break;
        case 3:
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => MultiPageForm()));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.laporan['status'];
    String statusMessage;

    // Menentukan pesan berdasarkan status
    if (status == 'Validation') {
      statusMessage =
          'Saat ini, data Anda sedang dalam proses validasi. Kami akan melakukan pengecekan yang menyeluruh untuk memastikan semua informasi yang Anda berikan adalah akurat dan lengkap. Mohon bersabar, kami akan memberi tahu Anda segera setelah proses ini selesai.';
    } else if (status == 'Approved') {
      statusMessage =
          'Kami dengan senang hati menginformasikan bahwa data Anda telah kami terima dan disetujui. Saat ini, laporan Anda sedang diproses untuk langkah-langkah selanjutnya. Terima kasih atas kesabaran dan kerjasama Anda.';
    } else if (status == 'Rejected') {
      statusMessage =
          'Kami menyesal memberitahukan bahwa data Anda tidak dapat diterima. Hal ini dikarenakan informasi yang diberikan dianggap kurang lengkap atau tidak sesuai dengan persyaratan yang ditetapkan. Silakan periksa kembali data Anda dan kirimkan ulang jika sudah diperbaiki.';
    } else {
      statusMessage =
          'Status laporan Anda tidak diketahui saat ini. Jika Anda merasa ini adalah kesalahan, silakan hubungi tim dukungan kami untuk mendapatkan bantuan lebih lanjut.';
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding untuk seluruh halaman
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian atas tampilan dengan logo
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image(
                    image: AssetImage('lib/image/Logo.png'),
                    width: 100,
                    height: 40,
                  ),
                ],
              ),
              const SizedBox(height: 20), // Jarak antara logo dan konten

              // Konten detail laporan
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E197E),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Gambar laporan
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        ApiConfig.getFetchImage(
                            widget.imagePath), // Menggunakan URL
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Text('Gambar tidak tersedia'));
                        },
                      ),
                    ),
                    const SizedBox(height: 10), // Jarak antara gambar dan teks

                    // Informasi laporan
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.laporan['name']}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Status Pelapor: ${widget.laporan['status_pelapor']}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tanggal Kekerasan: ${formatIsoDateToNormal(widget.laporan['tanggal_kekerasan'])}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            'Status: $status',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 20), // Jarak antara konten dan kotak status

              // Kotak untuk menampilkan pesan status
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.yellowAccent, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pesan Status:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 20), // Jarak antara kotak status dan kolom konsultasi

              // Kolom untuk konsultasi
              Container(
                padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(height: 10),
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
                                    builder: (context) => UserListChat()),
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
              const SizedBox(
                  height:
                      20), // Jarak antara kolom konsultasi dan bottom navigation bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
