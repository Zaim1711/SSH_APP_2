import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class Service {
  Future<http.Response> saveUser(
      String username, String email, String password) async {
    var uri = Uri.parse("http://10.0.2.2:8080/users");

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
