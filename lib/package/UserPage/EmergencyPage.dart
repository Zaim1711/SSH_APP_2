import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
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
  late MapController _mapController;
  LatLng? _currentLocation;
  Timer? _refreshTimer;
  bool _isDisposed = false;
  StreamSubscription? _locationSubscription; // Tambahkan ini

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _isDisposed = false;

    // Inisialisasi AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.3).animate(_animationController);

    _initializeServices();
  }

  void _initializeServices() async {
    try {
      webSocketService = WebSocketService();
      locationService = LocationService(webSocketService, _updateLocation);

      if (_isDisposed) return;

      _mapController = MapController();
      await locationService.startSendingLocation();

      if (_isDisposed) return;

      // Langganan stream lokasi
      _locationSubscription =
          locationService.locationStream.listen((newLocation) {
        if (!_isDisposed) {
          _updateLocation(newLocation);
        }
      });

      _refreshTimer = Timer.periodic(Duration(seconds: 1), (_) {
        if (_isDisposed) return;
        if (_currentLocation != null && mounted) {
          setState(() {
            _mapController.move(_currentLocation!, _mapController.zoom);
          });
        }
      });
    } catch (e) {
      print('Error initializing services: $e');
    }
  }

  void _updateLocation(LatLng location) {
    if (_isDisposed || !mounted) return;

    if (_currentLocation == null ||
        _currentLocation!.latitude != location.latitude ||
        _currentLocation!.longitude != location.longitude) {
      setState(() {
        _currentLocation = location;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted.");
    } else if (status.isDenied) {
      print("Location permission denied.");
    } else if (status.isPermanentlyDenied) {
      print("Location permission permanently denied.");
      // Mungkin arahkan pengguna ke pengaturan aplikasi untuk mengaktifkan izin.
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
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _currentLocation!,
                      zoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 90.0,
                            height: 95.0,
                            point: _currentLocation!,
                            builder: (ctx) => AnimatedBuilder(
                              animation: _opacityAnimation,
                              builder: (context, child) => Opacity(
                                opacity: _opacityAnimation.value,
                                child: Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Container(
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
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

    // Cancel timer
    _refreshTimer?.cancel();

    // Cancel location subscription
    _locationSubscription?.cancel();

    // Dispose animation controller
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();

    // Stop location service before closing WebSocket
    locationService.stopSendingLocation().then((_) {
      webSocketService.close();
    }).catchError((e) {
      print('Error during service cleanup: $e');
    });

    super.dispose();
  }
}
