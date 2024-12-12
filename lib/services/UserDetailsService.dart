import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ssh_aplication/model/DetailsUser.dart'; // Import model DetailsUser

class DetailsUserService {
  final String baseUrl =
      'http://10.0.0.2:8080/details'; // Ganti dengan URL backend Anda

  Future<DetailsUser?> getDetailsUser(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));

    if (response.statusCode == 200) {
      return DetailsUser.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user details');
    }
  }

  Future<void> createDetailsUser(DetailsUser detailsUser, int userId) async {
    final response = await http.post(
      Uri.parse(
          'http://10.0.0.2:8080/details?userId=$userId'), // Sertakan userId sebagai query parameter
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'nik': detailsUser.nik,
        'alamat': detailsUser.alamat,
        'nomor_telepon': detailsUser.nomorTelepon,
      }),
    );

    if (response.statusCode == 201) {
      // Berhasil menyimpan
    } else {
      throw Exception('Failed to create details user');
    }
  }
}
