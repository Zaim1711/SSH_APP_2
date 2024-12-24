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
  Timer? _refreshTimer;
  bool _isDisposed = false;

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;

    // Initialize the AnimationController first
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.3).animate(_animationController);

    // Then start async services
    _initializeServices();
  }

  void _initializeServices() async {
    try {
      webSocketService = WebSocketService();
      // Ensure locationService is not causing recursive calls
      locationService = LocationService(webSocketService, _updateLocation);

      if (_isDisposed) return;

      await locationService.startSendingLocation();

      if (_isDisposed) return;

      // Refresh map location every second
      _refreshTimer = Timer.periodic(Duration(seconds: 1), (_) {
        // Avoid unnecessary calls when widget is disposed or not mounted
        if (_isDisposed || !mounted) return;
        if (_currentLocation != null && _mapController != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              googleMaps.LatLng(
                _currentLocation!.latitude,
                _currentLocation!.longitude,
              ),
            ),
          );
        }
      });
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  // Update the location and ensure no unnecessary updates
  void _updateLocation(latlong.LatLng newLocation) {
    if (_currentLocation == null ||
        _currentLocation!.latitude != newLocation.latitude ||
        _currentLocation!.longitude != newLocation.longitude) {
      print('Location updated: $newLocation');
      setState(() {
        _currentLocation = newLocation;
      });
    } else {
      print('Location not updated (no change detected): $newLocation');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return Container();

    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Map'),
      ),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: CameraPosition(
                    target: googleMaps.LatLng(
                      _currentLocation!.latitude,
                      _currentLocation!.longitude,
                    ),
                    zoom: 15.0,
                  ),
                  markers: {
                    if (_currentLocation != null)
                      Marker(
                        markerId: MarkerId('currentLocation'),
                        position: googleMaps.LatLng(
                          _currentLocation!.latitude,
                          _currentLocation!.longitude,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed),
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

    // Cancel timer first
    _refreshTimer?.cancel();

    // Stop animation
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();

    // Stop location service before closing WebSocket
    _cleanupServices();

    super.dispose();
  }

  // This will cleanup services before disposing
  Future<void> _cleanupServices() async {
    try {
      await locationService.stopSendingLocation();
      await Future.delayed(
          Duration(milliseconds: 100)); // Give time for cleanup
      webSocketService.close();
    } catch (e) {
      print('Error during service cleanup: $e');
    }
  }
}
