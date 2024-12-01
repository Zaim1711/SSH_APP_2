import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/component/bottom_navigator.dart';
import 'package:ssh_aplication/package/DasboardPage.dart';
import 'package:ssh_aplication/package/ProfilePage.dart';

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

  @override
  void initState() {
    super.initState();
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

  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
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
  DateTime _selectedDateKekerasan = DateTime.now();
  DateTime? _selectedDateTanggalLahir;

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Format tanggal
      String formattedDateTimeKekerasan =
          _selectedDateKekerasan.toIso8601String();
      String formattedDateTimeTanggalLahir =
          _selectedDateTanggalLahir!.toIso8601String();

      // Ambil token akses dari SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accesToken');

      if (accessToken != null && !JwtDecoder.isExpired(accessToken)) {
        try {
          // Dekode token untuk mendapatkan ID pengguna
          var payload = JwtDecoder.decode(accessToken);
          this.id =
              payload['sub'].split(',')[0].toString(); // Ambil ID pengguna

          print('ID pengguna: ${this.id}'); // Debug print untuk ID pengguna

          // Memastikan id tidak kosong
          if (this.id.isNotEmpty) {
            _deskripsi = _deskripsiController.text;

            // Simpan gambar ke penyimpanan lokal
            String? imagePath;
            if (_selectedImage != null) {
              imagePath = await saveImageToDirectory(_selectedImage!);
            } else {
              print('Gambar tidak dipilih');
            }

            // Mengirimkan permintaan POST
            final response = await http.post(
              Uri.parse('http://10.0.2.2:8080/pengaduan/create'),
              headers: <String, String>{
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $accessToken',
              },
              body: jsonEncode(<String, dynamic>{
                'userId': this.id, // Pastikan ini bukan null
                'nik_user': _nik,
                'name': _nama,
                'jenis_kelamin': _jenisKelamin,
                'tempat_lahir': _tempatLahir,
                'tanggal_lahir': formattedDateTimeTanggalLahir,
                'pekerjaan': _pekerjaan,
                'status': 'Validation',
                'status_pelapor': _statuspelapor,
                'jenis_kekerasan': _jeniskekerasan,
                'deskripsi_kekerasan': _deskripsi,
                'tanggal_kekerasan': formattedDateTimeKekerasan,
                'bukti_kekerasan': imagePath,
              }),
            );

            if (response.statusCode == 200) {
              print('Pengaduan berhasil disimpan.');

              // Menampilkan dialog sukses
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Sukses'),
                    content: const Text('Pengaduan berhasil disimpan!'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Tutup dialog
                          Navigator.pushReplacementNamed(context,
                              '/dashboard'); // Pindah ke halaman dashboard
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            } else {
              print(
                  'Error saving event: ${response.statusCode} - ${response.body}');
              print('Payload: $payload');
            }
          } else {
            print('ID pengguna tidak ditemukan dalam token');
          }
        } catch (e) {
          print('Gagal mendekode token: $e');
        }
      } else {
        print('Token akses tidak tersedia atau telah kedaluwarsa');
      }
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
                initialValue: _nik,
                decoration: const InputDecoration(labelText: 'NIK'),
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
                initialValue: _nama,
                decoration: const InputDecoration(labelText: 'Nama'),
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
              Row(
                children: [
                  Radio(
                    value: 'Laki-laki',
                    groupValue: _jenisKelamin,
                    onChanged: (value) {
                      setState(() {
                        _jenisKelamin = value.toString();
                      });
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
                    },
                  ),
                  const Text('Perempuan',
                      style: TextStyle(color: Colors.black)),
                ],
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
              Row(
                children: [
                  const Text('Tanggal Lahir'),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate:
                            _selectedDateTanggalLahir ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _selectedDateTanggalLahir = selectedDate;
                        });
                      }
                    },
                    child: Text(
                      _selectedDateTanggalLahir != null
                          ? '${_selectedDateTanggalLahir!.day}/${_selectedDateTanggalLahir!.month}/${_selectedDateTanggalLahir!.year}'
                          : 'Pilih Tanggal Lahir',
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
              const Text(
                'Status Pelapor',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Radio(
                    value: 'Pelapor',
                    groupValue: _statuspelapor,
                    onChanged: (value) {
                      setState(() {
                        _statuspelapor = value.toString();
                      });
                    },
                  ),
                  const Text('Pelapor', style: TextStyle(color: Colors.black)),
                  Radio(
                    value: 'Saksi',
                    groupValue: _statuspelapor,
                    onChanged: (value) {
                      setState(() {
                        _statuspelapor = value.toString();
                      });
                    },
                  ),
                  const Text('Saksi', style: TextStyle(color: Colors.black)),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Jenis Kekerasan',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Radio(
                    value: 'KDRT',
                    groupValue: _jeniskekerasan,
                    onChanged: (value) {
                      setState(() {
                        _jeniskekerasan = value.toString();
                      });
                    },
                  ),
                  const Text('KDRT', style: TextStyle(color: Colors.black)),
                  Radio(
                    value: 'Persekusi',
                    groupValue: _jeniskekerasan,
                    onChanged: (value) {
                      setState(() {
                        _jeniskekerasan = value.toString();
                      });
                    },
                  ),
                  const Text('Persekusi',
                      style: TextStyle(color: Colors.black)),
                  Radio(
                    value: 'Bullying',
                    groupValue: _jeniskekerasan,
                    onChanged: (value) {
                      setState(() {
                        _jeniskekerasan = value.toString();
                      });
                    },
                  ),
                  const Text('Bullying', style: TextStyle(color: Colors.black)),
                ],
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
                  const Text('Tanggal Kekerasan'),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () async {
                      final selectedDateTime = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateKekerasan,
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
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Text(
                      '${_selectedDateKekerasan.day}/${_selectedDateKekerasan.month}/${_selectedDateKekerasan.year} ${_selectedDateKekerasan.hour}:${_selectedDateKekerasan.minute}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pilih Gambar'),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
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
                          child: _selectedImage == null
                              ? Icon(Icons.add_a_photo)
                              : Image.file(_selectedImage!),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _submitForm(context),
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
