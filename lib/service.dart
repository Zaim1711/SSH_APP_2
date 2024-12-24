import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ssh_aplication/services/ApiConfig.dart';

class Service {
  Future<http.Response> saveUser(
      String username, String email, String password) async {
    var uri = Uri.parse(ApiConfig.saveUser);

    Map<String, String> headers = {"Content-Type": "application/json"};

    Map<String, dynamic> data = {
      'username': username,
      'email': email,
      'password': password,
    };
    var body = json.encode(data);
    var response = await http.post(uri, headers: headers, body: body);

    return response;
  }
}
