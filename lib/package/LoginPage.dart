// ignore_for_file: must_be_immutable

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/component/My_TextField.dart';
import 'package:ssh_aplication/component/my_button.dart';
import 'package:ssh_aplication/component/password_TextField.dart';
import 'package:ssh_aplication/package/DasboardPage.dart';
import 'package:ssh_aplication/package/SignUpPage.dart';
import 'package:ssh_aplication/package/user.dart';
import 'package:ssh_aplication/services/ApiConfig.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  User user = User("", "");
  String url = (ApiConfig.loginUrl);

  Future<void> save(BuildContext context) async {
    // Validasi input
    if (user.email.isEmpty) {
      _showErrorDialog(context, 'Email tidak boleh kosong.');
      return; // Hentikan eksekusi jika email kosong
    }

    if (user.password.isEmpty) {
      _showErrorDialog(context, 'Password tidak boleh kosong.');
      return; // Hentikan eksekusi jika password kosong
    }

    final uri = Uri.parse(url);

    final Map<String, dynamic> requestData = {
      'email': user.email,
      'password': user.password,
    };

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestData),
    );

    // Pengecekan status kode respons
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final accessToken = responseData['accesToken'];

      if (accessToken != null && accessToken is String) {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        print('Token payload: $decodedToken');

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('accesToken', accessToken);

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DasboardPage()),
        );
      } else {
        // Jika format accessToken tidak valid
        print('Invalid accessToken format');
        _showErrorDialog(
            context, 'Format token tidak valid. Silakan coba lagi.');
      }
    } else {
      // Tangani respons gagal
      String errorMessage;
      switch (response.statusCode) {
        case 400:
          errorMessage =
              'Permintaan tidak valid. Periksa email dan kata sandi Anda.';
          break;
        case 401:
          errorMessage = 'Email atau kata sandi salah.';
          break;
        case 500:
          errorMessage =
              'Terjadi kesalahan di server. Silakan coba lagi nanti.';
          break;
        default:
          errorMessage = 'Gagal mengirim data: ${response.statusCode}';
      }
      print(errorMessage);
      _showErrorDialog(context, errorMessage);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kesalahan'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // void googleSignin() {

  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset('lib/image/Logo.png'),
                const SizedBox(height: 30.0),
                MyTextField(
                  controller: TextEditingController(text: user.email),
                  onChanged: (val) {
                    user.email = val;
                  },
                  hintText: 'Masukkan Email Anda',
                  obsecureText: false,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Alamat Email harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                MyTextFieldPass(
                  controller: TextEditingController(text: user.password),
                  onChanged: (val) {
                    user.password = val;
                  },
                  hintText: 'Masukkan Kata Sandi Anda',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Silakan masukkan kata sandi!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15.0),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Lupa Kata Sandi?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),
                MyButton(
                  onTap: () {
                    save(context);
                  },
                ),
                const SizedBox(height: 15),
                const SizedBox(height: 15),
                // Sign In row
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Belum punya akun? ",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _navigateToSignUp(context);
                        },
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            color: Color(0xFF0D187E),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _navigateToSignUp(BuildContext context) {
  Navigator.push(
    context,
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: animation,
        child: SignUpPage(),
      ),
    ),
  );
}
