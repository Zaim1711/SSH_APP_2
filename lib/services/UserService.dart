import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/model/userModel.dart';
import 'package:ssh_aplication/services/ApiConfig.dart';

class UserService {
  Future<User> fetchUser(String receiverId) async {
    // Retrieve the access token from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(
        'accesToken'); // Ensure the key matches what you used to store the token

    // Make the GET request to fetch the user
    final response = await http.get(
      Uri.parse(ApiConfig.getDataUser(receiverId)),
      headers: {
        'Authorization':
            'Bearer $accessToken', // Include the token in the headers
      },
    );

    // Check the response status
    if (response.statusCode == 200) {
      // Decode the JSON response and return a User object
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Failed to load user'); // Handle error if the request fails
    }
  }

  //get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //get user Stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();

        return user;
      }).toList();
    });
  }

  //send message
  Future<void> sendMessage(String receiverId, String message) async {}
}
