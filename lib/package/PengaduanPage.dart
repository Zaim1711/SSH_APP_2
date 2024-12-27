import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/component/bottom_navigator.dart';
import 'package:ssh_aplication/package/DasboardPage.dart';
import 'package:ssh_aplication/package/InputUserDetails.dart';
import 'package:ssh_aplication/package/ProfilePage.dart';
import 'package:ssh_aplication/services/ApiConfig.dart';
import 'package:ssh_aplication/services/NotificatioonService.dart';
import 'package:video_player/video_player.dart';

class MultiPageForm extends StatefulWidget {
  @override
  _MultiPageFormState createState() => _MultiPageFormState();
}

class _MultiPageFormState extends State<MultiPageForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _page1Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _page2Key = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  final PageStorageBucket bucket = PageStorageBucket();
  final TextEditingController _deskripsiController = TextEditingController();
  int _currentIndex = 3;
  Map<String, dynamic> payload = {};
  String id = '';
  TextEditingController _nikController =
      TextEditingController(); // Controller untuk NIK

  TextEditingController _namaController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _tanggalKekerasanController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  String? _fileType;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _checkUserDetails();
  }

  @override
  void dispose() {
    _cleanupControllers();
    super.dispose();
  }

  void _cleanupControllers() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController = null;
    _chewieController = null;
  }

  Future<void> _checkUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null && !JwtDecoder.isExpired(accessToken)) {
      try {
        var payload = JwtDecoder.decode(accessToken);
        this.id = payload['sub'].split(',')[0].toString();

        String nama =
            payload['sub'].split(',')[2].toString(); // Ambil ID pengguna

        final response = await http.get(
          Uri.parse(ApiConfig.getcheckUserUrl(id)),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );
        if (response.statusCode == 200) {
          var userDetails = jsonDecode(response.body);
          print(response.body);

          String nik = userDetails['nik'].toString();
          setState(() {
            _nikController.text = nik; // Mengatur nilai controller
            _namaController.text = nama;
          });

          if (userDetails.isEmpty) {
            _showDataNotFoundDialog();
          }
        } else if (response.statusCode == 404) {
          // Tangani 404 Not Found
          _showDataNotFoundDialog();
        } else {
          print(
              'Error fetching user details: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Gagal mendekode token: $e');
      }
    } else {
      print('Token akses tidak tersedia atau telah kedaluwarsa');
    }
  }

  void _showDataNotFoundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile anda belum lengkap'),
          content: const Text(
              'Data profile anda belum lengkap. Silakan isi data pengguna terlebih dahulu agar dapat melakukan pelaporan.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                // Navigasi ke halaman pengisian data pengguna
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InputUserDetails()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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

  Future<void> _initializeVideo() async {
    // Cleanup old controllers first
    _cleanupControllers();

    _videoPlayerController = VideoPlayerController.file(_selectedFile!);
    try {
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        placeholder: Center(child: CircularProgressIndicator()),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: TextStyle(color: Colors.red),
            ),
          );
        },
      );
      setState(() {});
    } catch (e) {
      print('Error initializing video: $e');
      _cleanupControllers();
      setState(() {
        // Reset file selection if video initialization fails
        _selectedFile = null;
        _fileType = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error loading video. Please try another file.')),
      );
    }
  }

  Future<void> _pickFile() async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Jenis Bukti'),
          content: Text(_selectedFile != null
              ? 'File yang dipilih akan diganti'
              : 'Pilih jenis file yang akan diunggah'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Image'),
              child: Text('Gambar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'Video'),
              child: Text('Video'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'Audio'),
              child: Text('Rekaman Suara'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (result == 'Image') {
        final XFile? pickedFile =
            await _picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() {
            _selectedFile = File(pickedFile.path);
            _fileType = 'image';
          });
        }
      } else if (result == 'Video') {
        final XFile? pickedFile =
            await _picker.pickVideo(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() {
            _selectedFile = File(pickedFile.path);
            _fileType = 'video';
          });
          await _initializeVideo();
        }
      }
    }
  }

  Future<String?> saveImageToDirectory(File imageFile) async {
    try {
      Directory directory = await getApplicationDocumentsDirectory();
      String imageName = '${DateTime.now().millisecondsSinceEpoch}.png';
      String imagePath = '${directory.path}/image_form/$imageName';

      // Buat direktori jika belum ada
      await Directory('${directory.path}/image_form/').create(recursive: true);

      File savedImage = await imageFile.copy(imagePath);
      return savedImage.path;
    } catch (e) {
      print('Gagal menyimpan gambar: $e');
      return null;
    }
  }

  String _nik = '';
  String _nama = '';
  String _jenisKelamin = '';
  String _tempatLahir = '';
  String _pekerjaan = '';
  String _status = '';
  String _statuspelapor = '';
  String _jeniskekerasan = '';
  String _deskripsi = '';
  DateTime? _selectedDateTanggalLahir;
  DateTime _selectedDateKekerasan = DateTime.now();

  Future<void> _validateAndProcessFile(File file) async {
    // Convert bytes to MB untuk memudahkan pembacaan
    final bytes = await file.length();
    final mb = bytes / (1024 * 1024);

    // Batasi ukuran file maksimal (misalnya 5MB)
    const maxSizeMB = 10.0;

    if (mb > maxSizeMB) {
      throw Exception(
          'Ukuran file terlalu besar. Maksimal ${maxSizeMB}MB, file Anda: ${mb.toStringAsFixed(2)}MB');
    }
  }

  // Fungsi untuk mengkompresi gambar
  Future<File> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        dir.path + "/" + DateTime.now().millisecondsSinceEpoch.toString();

    var result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70, // Kualitas kompresi (0-100)
      minWidth: 1024, // Lebar maksimal
      minHeight: 1024, // Tinggi maksimal
    );

    return File(result!.path);
  }

  Future<void> _submitForm(BuildContext context) async {
    try {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        if (_selectedFile != null) {
          try {
            await _validateAndProcessFile(_selectedFile!);
          } catch (e) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text(e.toString()),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
            return; // Hentikan proses jika validasi file gagal
          }
        }

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // Format tanggal
        String formattedDateTimeKekerasan =
            _selectedDateKekerasan!.toIso8601String();
        String formattedDateTimeTanggalLahir =
            _selectedDateTanggalLahir!.toIso8601String();

        // Ambil token akses dari SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? accessToken = prefs.getString('accesToken');

        if (accessToken == null) {
          Navigator.of(context).pop(); // Tutup loading
          throw Exception('Token akses tidak tersedia');
        }

        if (JwtDecoder.isExpired(accessToken)) {
          Navigator.of(context).pop(); // Tutup loading
          Navigator.of(context).pushReplacementNamed('/login');
          throw Exception('Token telah kedaluwarsa, silakan login kembali');
        }

        // Dekode token untuk mendapatkan ID pengguna
        var payload = JwtDecoder.decode(accessToken);
        String id = payload['sub'].split(',')[0].toString();

        if (id.isEmpty) {
          Navigator.of(context).pop(); // Tutup loading
          throw Exception('ID pengguna tidak ditemukan dalam token');
        }

        _deskripsi = _deskripsiController.text;

        // Buat request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConfig.cretePengaduan),
        );

        // Set timeout
        request.headers.addAll({
          'Authorization': 'Bearer $accessToken',
          'Connection': 'keep-alive',
        });

        // Menambahkan field lainnya
        request.fields.addAll({
          'userId': id,
          'nik_user': _nik!,
          'name': _nama!,
          'jenis_kelamin': _jenisKelamin!,
          'tempat_lahir': _tempatLahir!,
          'tanggal_lahir': formattedDateTimeTanggalLahir,
          'pekerjaan': _pekerjaan!,
          'status': 'Validation',
          'status_pelapor': _statuspelapor!,
          'jenis_kekerasan': _jeniskekerasan!,
          'deskripsi_kekerasan': _deskripsi!,
          'tanggal_kekerasan': formattedDateTimeKekerasan,
        });

        // Handle file upload
        if (_selectedFile != null) {
          print('Selected file: ${_selectedFile!.path}');

          // Dapatkan tipe MIME dari file yang dipilih
          String? mimeType = lookupMimeType(_selectedFile!.path);

          // Cek apakah mimeType valid
          if (mimeType == null) {
            throw Exception('Invalid file type. Please upload a valid file.');
          }

          // Tentukan contentType berdasarkan mimeType
          MediaType contentType;
          if (mimeType.startsWith('video/')) {
            contentType = MediaType(
                'video', 'mp4'); // Atau sesuai dengan tipe video yang diupload
          } else if (mimeType.startsWith('image/')) {
            contentType = MediaType('image',
                'jpeg'); // Atau sesuai dengan tipe gambar yang diupload
          } else {
            throw Exception(
                'Invalid file type. Please upload an image or video file.');
          }

          try {
            // Tambahkan file ke request
            var file = await http.MultipartFile.fromPath(
              'bukti_kekerasan',
              _selectedFile!.path, // Pastikan ini adalah path file yang benar
              contentType: contentType, // Gunakan contentType yang sesuai
            );
            request.files.add(file);
          } catch (e) {
            print('Error uploading file: $e');
            Navigator.of(context).pop(); // Tutup loading
            throw Exception('Gagal mengupload file: $e');
          }
        }
        // Kirim request dengan timeout
        var responseStream = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timeout');
          },
        );

        // Convert stream to response
        var response = await http.Response.fromStream(responseStream);

        // Tutup loading dialog
        Navigator.of(context).pop();

        if (response.statusCode == 200) {
          // Kirim notifikasi
          String receiverId =
              '8'; // Ganti dengan ID pengguna yang akan menerima notifikasi
          String senderName = _nama;
          try {
            await _notificationService.sendNotificationPengaduan(
              receiverId, // Receiver ID
              'Laporan dari $senderName',
              'Pengaduan Kekerasan $_jeniskekerasan',
            );
          } catch (e) {
            print('Error sending notification: $e');
          }

          // Show success dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Sukses'),
                content: const Text('Pengaduan berhasil disimpan!'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          throw Exception('Error saving pengaduan: ${response.statusCode}');
        }
      }
    } catch (e) {
      // Handle semua error
      Navigator.of(context).pop(); // Tutup loading jika masih terbuka
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  int _currentPage = 0;

  List<bool> _pageFilledStatus = [false, false];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PageStorage(
          bucket: bucket,
          child: Column(
            children: [
              Container(
                width: 450,
                height: 200,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Image(
                      image: AssetImage('lib/image/Logo.png'),
                      width: 100,
                      height: 80,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        "Form Event",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D187E),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    _buildPageIndicator(),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [_buildPage1(), _buildPage2()],
                ),
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

  Widget _buildPageIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIndicatorItem(0),
            const SizedBox(width: 50),
            _buildIndicatorItem(1),
          ],
        ),
        Container(
          height: 2,
          width: 50,
          color: Colors.grey,
        ),
        _currentPage == 1
            ? Positioned(
                left: 16.0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  },
                ),
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _buildIndicatorItem(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 500),
            curve: Curves.ease,
          );
        });
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentPage == index
              ? Colors.green
              : (_pageFilledStatus[index] ? Colors.green : Colors.grey),
        ),
        child: Icon(
          _pageFilledStatus[index] ? Icons.check : null,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      child: Form(
        key: _page1Key,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nikController, // Menggunakan controller untuk NIK
                decoration: const InputDecoration(labelText: 'NIK'),
                readOnly: true, // Menjadikan field ini tidak dapat diedit
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NIK tidak boleh kosong';
                  }
                  return null;
                },
                onSaved: (value) {
                  _nik = value ?? '';
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
                onSaved: (value) {
                  _nama = value ?? '';
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Jenis Kelamin',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FormField<String>(
                validator: (value) {
                  if (_jenisKelamin == null || _jenisKelamin.isEmpty) {
                    return 'Jenis kelamin tidak boleh kosong';
                  }
                  return null;
                },
                builder: (FormFieldState<String> state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio(
                            value: 'Laki-laki',
                            groupValue: _jenisKelamin,
                            onChanged: (value) {
                              setState(() {
                                _jenisKelamin = value.toString();
                              });
                              state.didChange(value);
                            },
                          ),
                          const Text('Laki-laki',
                              style: TextStyle(color: Colors.black)),
                          Radio(
                            value: 'Perempuan',
                            groupValue: _jenisKelamin,
                            onChanged: (value) {
                              setState(() {
                                _jenisKelamin = value.toString();
                              });
                              state.didChange(value);
                            },
                          ),
                          const Text('Perempuan',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                      if (state.hasError)
                        Text(
                          state.errorText!,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _tempatLahir,
                decoration: const InputDecoration(labelText: 'Tempat Lahir'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tempat Lahir tidak boleh kosong';
                  }
                  return null;
                },
                onSaved: (value) {
                  _tempatLahir = value ?? '';
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller:
                          _tanggalLahirController, // Menggunakan controller
                      readOnly: true, // Membuat field ini hanya bisa dibaca
                      decoration: const InputDecoration(
                        labelText: 'Pilih Tanggal Lahir',
                      ),
                      validator: (value) {
                        if (_selectedDateTanggalLahir == null) {
                          return 'Tanggal lahir tidak boleh kosong';
                        }
                        return null; // Jika valid, kembalikan null
                      },
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate:
                              _selectedDateTanggalLahir ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            _selectedDateTanggalLahir =
                                selectedDate; // Simpan tanggal lahir yang dipilih
                            _tanggalLahirController.text =
                                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'; // Update controller
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: _pekerjaan,
                decoration: const InputDecoration(labelText: 'Pekerjaan'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pekerjaan tidak boleh kosong';
                  }
                  return null;
                },
                onSaved: (value) {
                  _pekerjaan = value ?? '';
                },
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page1Key.currentState!.validate()) {
                      _page1Key.currentState!.save();
                      setState(() {
                        _pageFilledStatus[0] = true;
                      });
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      child: Form(
        key: _page2Key,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Pelapor
              const Text(
                'Status Pelapor',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              FormField<String>(
                validator: (value) {
                  if (_statuspelapor == null || _statuspelapor.isEmpty) {
                    return 'Pilih status pelapor';
                  }
                  return null;
                },
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio(
                            value: 'Pelapor',
                            groupValue: _statuspelapor,
                            onChanged: (value) {
                              setState(() {
                                _statuspelapor = value.toString();
                              });
                              state.didChange(value);
                            },
                          ),
                          const Text('Pelapor',
                              style: TextStyle(color: Colors.black)),
                          Radio(
                            value: 'Saksi',
                            groupValue: _statuspelapor,
                            onChanged: (value) {
                              setState(() {
                                _statuspelapor = value.toString();
                              });
                              state.didChange(value);
                            },
                          ),
                          const Text('Saksi',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                      if (state.hasError)
                        Text(state.errorText!,
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Jenis Kekerasan
              const Text(
                'Jenis Kekerasan',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              FormField<String>(
                validator: (value) {
                  if (_jeniskekerasan == null || _jeniskekerasan.isEmpty) {
                    return 'Pilih jenis kekerasan';
                  }
                  return null;
                },
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio(
                            value: 'Online',
                            groupValue: _jeniskekerasan,
                            onChanged: (value) {
                              setState(() {
                                _jeniskekerasan = value.toString();
                              });
                              state.didChange(value);
                            },
                          ),
                          const Text('Online',
                              style: TextStyle(color: Colors.black)),
                          Radio(
                            value: 'Verbal',
                            groupValue: _jeniskekerasan,
                            onChanged: (value) {
                              setState(() {
                                _jeniskekerasan = value.toString();
                              });
                              state.didChange(value);
                            },
                          ),
                          const Text('Verbal',
                              style: TextStyle(color: Colors.black)),
                          Radio(
                            value: 'Fisik',
                            groupValue: _jeniskekerasan,
                            onChanged: (value) {
                              setState(() {
                                _jeniskekerasan = value.toString();
                              });
                              state.didChange(value);
                            },
                          ),
                          const Text('Fisik',
                              style: TextStyle(color: Colors.black)),
                        ],
                      ),
                      if (state.hasError)
                        Text(state.errorText!,
                            style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
              TextFormField(
                controller: _deskripsiController,
                decoration: InputDecoration(labelText: 'Deskripsi Kekerasan'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
                // Hapus initialValue
                // initialValue: _deskripsi,
                onSaved: (value) {
                  _deskripsi = value ?? '';
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller:
                          _tanggalKekerasanController, // Menggunakan controller
                      readOnly: true, // Membuat field ini hanya bisa dibaca
                      decoration: InputDecoration(
                        labelText: _selectedDateKekerasan != null
                            ? '${_selectedDateKekerasan!.day}/${_selectedDateKekerasan!.month}/${_selectedDateKekerasan!.year}'
                            : 'Pilih Tanggal Kekerasan',
                      ),
                      validator: (value) {
                        if (_selectedDateKekerasan == null) {
                          return 'Tanggal kekerasan tidak boleh kosong';
                        }
                        return null; // Jika valid, kembalikan null
                      },
                      onTap: () async {
                        final selectedDateTime = await showDatePicker(
                          context: context,
                          initialDate: _selectedDateKekerasan ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (selectedDateTime != null) {
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (selectedTime != null) {
                            setState(() {
                              _selectedDateKekerasan = DateTime(
                                selectedDateTime.year,
                                selectedDateTime.month,
                                selectedDateTime.day,
                              ); // Simpan tanggal kekerasan yang dipilih
                              _tanggalKekerasanController.text =
                                  '${_selectedDateKekerasan!.day}/${_selectedDateKekerasan!.month}/${_selectedDateKekerasan!.year}}'; // Update controller
                            });
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Bukti Laporan',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          InkWell(
                            onTap: _pickFile,
                            child: Container(
                              width: 300,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Color(0xFFF4F4F4),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _selectedFile == null
                                  ? Icon(Icons.add_a_photo)
                                  : _fileType == 'image'
                                      ? Image.file(
                                          _selectedFile!,
                                          fit: BoxFit.cover,
                                        )
                                      : _fileType == 'video' &&
                                              _chewieController != null
                                          ? Chewie(
                                              controller: _chewieController!)
                                          : Center(
                                              child:
                                                  CircularProgressIndicator()),
                            ),
                          ),
                          if (_selectedFile != null)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: IconButton(
                                icon: Icon(Icons.change_circle,
                                    color: Colors.blue),
                                onPressed: _pickFile,
                                tooltip: 'Ganti file',
                              ),
                            ),
                        ],
                      ),
                      if (_fileType == 'video' &&
                          _videoPlayerController != null)
                        IconButton(
                          icon: Icon(
                            _videoPlayerController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          onPressed: () {
                            setState(() {
                              if (_videoPlayerController!.value.isPlaying) {
                                _videoPlayerController!.pause();
                              } else {
                                _videoPlayerController!.play();
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page2Key.currentState!.validate()) {
                      _submitForm(context);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
