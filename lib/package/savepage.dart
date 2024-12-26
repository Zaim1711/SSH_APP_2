import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as googleMaps;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:ssh_aplication/services/LocationService.dart';
import 'package:ssh_aplication/services/WebSocketConfig.dart';

class EmergencyPage extends StatefulWidget {
  @override
  _EmergencyPageState createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage>
    with SingleTickerProviderStateMixin {
  late WebSocketService webSocketService;
  late LocationService locationService;
  GoogleMapController? _mapController;
  latlong.LatLng? _currentLocation;
  bool _isDisposed = false;
  bool _isMapReady = false; // Menandai apakah peta sudah siap

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.3).animate(_animationController);

    // Inisialisasi layanan tanpa mengambil lokasi terlebih dahulu
    _initializeServices();
  }

  void _initializeServices() async {
    try {
      webSocketService = WebSocketService();
      locationService = LocationService(webSocketService, _updateLocation);

      if (_isDisposed) return;

      // Tampilkan peta dengan posisi default
      _currentLocation =
          latlong.LatLng(-7.273197, 112.737657); // Ganti dengan lokasi default

      // Mulai mendengarkan stream lokasi setelah peta siap
      locationService.locationStream.listen((newLocation) {
        if (_isMapReady) {
          _updateLocation(newLocation);
        }
      });
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  void _updateLocation(latlong.LatLng newLocation) {
    print('New location received: $newLocation');
    if (_currentLocation == null ||
        _currentLocation!.latitude != newLocation.latitude ||
        _currentLocation!.longitude != newLocation.longitude) {
      print('Location updated: $newLocation');
      setState(() {
        _currentLocation = newLocation;
      });

      // Memindahkan kamera peta ke lokasi baru
      if (_mapController != null) {
        _mapController?.animateCamera(
          googleMaps.CameraUpdate.newLatLng(
            googleMaps.LatLng(
              newLocation.latitude,
              newLocation.longitude,
            ),
          ),
        );
      }
    } else {
      print('Location not updated (no change detected): $newLocation');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true; // Tandai bahwa peta sudah siap

    if (_currentLocation != null) {
      _mapController?.animateCamera(
        googleMaps.CameraUpdate.newLatLng(
          googleMaps.LatLng(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return Container();

    print('Current location: $_currentLocation');

    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Map'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: googleMaps.CameraPosition(
              target: googleMaps.LatLng(
                _currentLocation?.latitude ??
                    -7.273197, // Ganti dengan lokasi default
                _currentLocation?.longitude ??
                    112.737657, // Ganti dengan lokasi default
              ),
              zoom: 15.0,
            ),
            markers: {
              if (_currentLocation != null)
                googleMaps.Marker(
                  markerId: googleMaps.MarkerId('currentLocation'),
                  position: googleMaps.LatLng(
                    _currentLocation!.latitude,
                    _currentLocation!.longitude,
                  ),
                  icon: googleMaps.BitmapDescriptor.defaultMarkerWithHue(
                      googleMaps.BitmapDescriptor.hueRed),
                ),
            },
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              color: Colors.green.withOpacity(0.2),
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Sinyal SOS telah dikirim dan sedang dalam pemantauan.",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Logika tambahan untuk tombol jika diperlukan
              },
              child: Text('Chat'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                textStyle: TextStyle(fontSize: 18.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;

    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();

    _cleanupServices();

    super.dispose();
  }

  Future<void> _cleanupServices() async {
    try {
      await locationService.stopSendingLocation();
      webSocketService.close();
    } catch (e) {
      print('Error during service cleanup: $e');
    }
  }
}
