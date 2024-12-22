import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/services/WebSocketConfig.dart';

class LocationService {
  final WebSocketService webSocketService;
  Map<String, dynamic> payload = {};
  Timer? timer;

  LocationService(this.webSocketService);

  void startSendingLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    payload = JwtDecoder.decode(accessToken!);
    String name = payload['sub'].split(',')[2];
    String id = payload['sub'].split(',')[0];
    // Mengambil nilai 'name' dari token JWT

    timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String locationData =
          '{"latitude": ${position.latitude}, "longitude": ${position.longitude}, "userId": "$id"}';
      webSocketService.sendMessage(locationData);

      print("Location sent: $locationData");
    });
  }

  void stopSendingLocation() {
    timer?.cancel();
  }
}
