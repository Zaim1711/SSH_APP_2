import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/services/WebSocketConfig.dart';

class LocationService {
  final WebSocketService webSocketService;
  Map<String, dynamic> payload = {};
  Timer? timer;
  late Function(LatLng) onLocationUpdate; // Ensure correct function signature
  StreamController<LatLng> _locationController = StreamController<LatLng>();

  LocationService(this.webSocketService, this.onLocationUpdate);
  Stream<LatLng> get locationStream => _locationController.stream;

  Future<void> startSendingLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null) {
      payload = JwtDecoder.decode(accessToken);
      String name = payload['sub'].split(',')[2];
      String id = payload['sub'].split(',')[0];

      timer = Timer.periodic(Duration(seconds: 1), (timer) async {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        String locationData =
            '{"latitude": ${position.latitude}, "longitude": ${position.longitude}, "userId": "$id"}';
        webSocketService.sendMessage(locationData);

        // Update posisi lokasi di peta
        onLocationUpdate(LatLng(position.latitude, position.longitude));

        print("Location sent: $locationData");
      });
    }
  }

  Future<void> stopSendingLocation() async {
    if (timer != null) {
      timer!.cancel();
      timer = null;
      print("Timer stopped.");
    }
  }
}
