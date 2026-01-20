import 'dart:async';
import 'package:cepattanggap/controllers/iot_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../models/iot_data_model.dart';
import 'package:intl/intl.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  late final FirebaseService _firebaseService;

  // ✅ Real-time GPS tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  bool isTrackingLocation = false;
  LatLng userLocation = LatLng(-6.2088, 106.8456);
  bool isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    try {
      _firebaseService = Get.find<FirebaseService>();
    } catch (e) {
      _firebaseService = Get.put(FirebaseService(), permanent: true);
    }

    // ✅ Start real-time GPS tracking
    _startLocationTracking();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // ✅ REAL-TIME GPS TRACKING
  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => isLoadingLocation = false);
        _showLocationError('Location service tidak aktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => isLoadingLocation = false);
          _showLocationError('Permission lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => isLoadingLocation = false);
        _showLocationError('Permission lokasi ditolak permanen');
        return;
      }

      // Get initial position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
          isLoadingLocation = false;
        });
        _mapController.move(userLocation, 15.0);
      }

      // ✅ Start streaming location updates
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update setiap user bergerak 10 meter
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          if (mounted) {
            setState(() {
              userLocation = LatLng(position.latitude, position.longitude);
              isTrackingLocation = true;
            });

            // ✅ Auto-center map ke lokasi user
            _mapController.move(userLocation, _mapController.camera.zoom);

            print(
              '📍 GPS Updated: ${position.latitude}, ${position.longitude}',
            );
          }
        },
        onError: (error) {
          print('❌ GPS Tracking Error: $error');
          if (mounted) {
            setState(() => isTrackingLocation = false);
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => isLoadingLocation = false);
      _showLocationError('Gagal mendapatkan lokasi: $e');
    }
  }

  void _showLocationError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _centerToUser() {
    _mapController.move(userLocation, 15.0);
  }

  void _openFullScreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FullScreenMapPage(
              userLocation: userLocation,
              isTracking: isTrackingLocation,
            ),
      ),
    );
  }

  IconData _getIconForDevice(IoTData device) {
    final disaster = device.disasterType;
    if (disaster == null) return Icons.check_circle;

    switch (disaster) {
      case DisasterType.earthquake:
        return Icons.warning_amber;
      case DisasterType.flood:
        return Icons.water;
      case DisasterType.fire:
        return Icons.local_fire_department;
      case DisasterType.earthquakeFlood:
      case DisasterType.earthquakeFire:
      case DisasterType.floodFire:
      case DisasterType.multiple:
        return Icons.emergency;
    }
  }

  Color _getColorForDevice(IoTData device) {
    final disaster = device.disasterType;
    if (disaster == null) return Colors.green;

    switch (disaster) {
      case DisasterType.earthquake:
        return Colors.orange;
      case DisasterType.flood:
        return Colors.blue;
      case DisasterType.fire:
        return Colors.red;
      case DisasterType.earthquakeFlood:
      case DisasterType.earthquakeFire:
      case DisasterType.floodFire:
      case DisasterType.multiple:
        return Colors.red.shade900;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (_firebaseService.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data IoT...'),
                ],
              ),
            );
          }

          if (_firebaseService.error.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${_firebaseService.error.value}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () => _firebaseService.listenToIoTDataWithImages(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final iotDevices = _firebaseService.iotDevices;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === MAPS CONTAINER ===
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: userLocation,
                              initialZoom: 15.0,
                              minZoom: 5.0,
                              maxZoom: 18.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c', 'd'],
                                maxZoom: 19,
                                userAgentPackageName: 'id.alertquake.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  // ✅ User marker dengan GPS tracking indicator
                                  Marker(
                                    point: userLocation,
                                    width: 40,
                                    height: 40,
                                    child: Stack(
                                      children: [
                                        const Icon(
                                          Icons.person_pin_circle,
                                          color: Colors.blue,
                                          size: 40,
                                        ),
                                        if (isTrackingLocation)
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // IoT device markers
                                  ...iotDevices.map((device) {
                                    return Marker(
                                      point: device.position,
                                      width: 32,
                                      height: 32,
                                      child: Icon(
                                        _getIconForDevice(device),
                                        color: _getColorForDevice(device),
                                        size: 32,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                          // FAB untuk center ke user
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: FloatingActionButton(
                              heroTag: 'mainPageCenterBtn',
                              mini: true,
                              backgroundColor: Colors.white,
                              elevation: 2,
                              onPressed: _centerToUser,
                              child: Icon(
                                isTrackingLocation
                                    ? Icons.gps_fixed
                                    : Icons.my_location,
                                color:
                                    isTrackingLocation
                                        ? Colors.green
                                        : Colors.blue,
                                size: 20,
                              ),
                            ),
                          ),
                          // Button OPEN MAPS
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              elevation: 2,
                              child: InkWell(
                                onTap: _openFullScreenMap,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.zoom_out_map,
                                        size: 16,
                                        color: Colors.black87,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'OPEN MAPS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // ✅ GPS Tracking Indicator
                          if (isTrackingLocation)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.gps_fixed,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'GPS Tracking',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // === CARD DESKRIPSI ===
                  Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Deskripsi:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  if (isTrackingLocation)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.gps_fixed,
                                            size: 10,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Live',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${iotDevices.length} Device${iotDevices.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Posisi User
                          Row(
                            children: [
                              Icon(
                                isTrackingLocation
                                    ? Icons.person_pin_circle
                                    : Icons.location_searching,
                                color:
                                    isTrackingLocation
                                        ? Colors.blue
                                        : Colors.grey,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isTrackingLocation
                                      ? 'Posisi Anda (Live Tracking)'
                                      : 'Posisi Anda',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        isTrackingLocation
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isLoadingLocation) ...[
                                const SizedBox(width: 8),
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          // IoT Devices
                          if (iotDevices.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Belum ada device IoT terdaftar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            ...iotDevices.map((device) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getIconForDevice(device),
                                      color: _getColorForDevice(device),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${device.id} - ${device.iotStatus}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    if (device.disasterType != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getColorForDevice(
                                            device,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'ALERT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getColorForDevice(device),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // === LIST UPDATE LOKASI ===
                  if (iotDevices.isEmpty)
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.sensors_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada data dari IoT',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pastikan ESP32 sudah terhubung',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...iotDevices.map((device) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side:
                                device.disasterType != null
                                    ? BorderSide(
                                      color: _getColorForDevice(device),
                                      width: 2,
                                    )
                                    : BorderSide.none,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getIconForDevice(device),
                                      color: _getColorForDevice(device),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device.id,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            device.statusMessage,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  device.disasterType != null
                                                      ? _getColorForDevice(
                                                        device,
                                                      )
                                                      : Colors.black54,
                                              fontWeight:
                                                  device.disasterType != null
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                // Sensor Data
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    _buildSensorChip(
                                      Icons.thermostat,
                                      '${device.temperature.toStringAsFixed(1)}°C',
                                      Colors.orange,
                                    ),
                                    _buildSensorChip(
                                      Icons.water_drop,
                                      '${device.humidity.toStringAsFixed(0)}%',
                                      Colors.blue,
                                    ),
                                    _buildSensorChip(
                                      Icons.waves,
                                      '${device.waterLevel.toStringAsFixed(0)} cm',
                                      Colors.cyan,
                                    ),
                                    if (device.earthquakeIntensity > 0)
                                      _buildSensorChip(
                                        Icons.warning_amber,
                                        'EQ: ${device.earthquakeIntensity.toStringAsFixed(1)}',
                                        Colors.amber,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // GPS Status & Timestamp
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          device.gpsValid
                                              ? Icons.gps_fixed
                                              : Icons.gps_off,
                                          size: 14,
                                          color:
                                              device.gpsValid
                                                  ? Colors.green
                                                  : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          device.gpsValid
                                              ? '${device.satellites} sats'
                                              : 'No GPS',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatTimestamp(device.lastUpdated),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSensorChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: _getDarkerColor(color),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    return Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
  }
}

// === FULLSCREEN MAP WITH GPS TRACKING ===
class FullScreenMapPage extends StatefulWidget {
  final LatLng userLocation;
  final bool isTracking;

  const FullScreenMapPage({
    super.key,
    required this.userLocation,
    this.isTracking = false,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  late final MapController _fullScreenMapController;
  late final FirebaseService _firebaseService;

  // ✅ GPS Tracking for fullscreen
  StreamSubscription<Position>? _positionStreamSubscription;
  late LatLng userLocation;
  bool isTrackingLocation = false;

  @override
  void initState() {
    super.initState();
    _fullScreenMapController = MapController();
    userLocation = widget.userLocation;
    isTrackingLocation = widget.isTracking;

    try {
      _firebaseService = Get.find<FirebaseService>();
    } catch (e) {
      _firebaseService = Get.put(FirebaseService(), permanent: true);
    }

    // Start tracking if enabled
    if (widget.isTracking) {
      _startLocationTracking();
    }
  }

  @override
  void dispose() {
    _fullScreenMapController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
          isTrackingLocation = true;
        });
        _fullScreenMapController.move(
          userLocation,
          _fullScreenMapController.camera.zoom,
        );
      }
    });
  }

  void _centerToUser() {
    _fullScreenMapController.move(userLocation, 15.0);
  }

  IconData _getIconForDevice(IoTData device) {
    final disaster = device.disasterType;
    if (disaster == null) return Icons.check_circle;

    switch (disaster) {
      case DisasterType.earthquake:
        return Icons.warning_amber;
      case DisasterType.flood:
        return Icons.water;
      case DisasterType.fire:
        return Icons.local_fire_department;
      case DisasterType.earthquakeFlood:
      case DisasterType.earthquakeFire:
      case DisasterType.floodFire:
      case DisasterType.multiple:
        return Icons.emergency;
    }
  }

  Color _getColorForDevice(IoTData device) {
    final disaster = device.disasterType;
    if (disaster == null) return Colors.green;

    switch (disaster) {
      case DisasterType.earthquake:
        return Colors.orange;
      case DisasterType.flood:
        return Colors.blue;
      case DisasterType.fire:
        return Colors.red;
      case DisasterType.earthquakeFlood:
      case DisasterType.earthquakeFire:
      case DisasterType.floodFire:
      case DisasterType.multiple:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
            final iotDevices = _firebaseService.iotDevices;

            return FlutterMap(
              mapController: _fullScreenMapController,
              options: MapOptions(
                initialCenter: userLocation,
                initialZoom: 15.0,
                minZoom: 5.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  maxZoom: 19,
                  userAgentPackageName: 'id.alertquake.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation,
                      width: 50,
                      height: 50,
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 50,
                          ),
                          if (isTrackingLocation)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...iotDevices.map((device) {
                      return Marker(
                        point: device.position,
                        width: 40,
                        height: 40,
                        child: Icon(
                          _getIconForDevice(device),
                          color: _getColorForDevice(device),
                          size: 40,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            );
          }),
          Positioned(
            top: 40,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'fullScreenBackBtn',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.black87),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              heroTag: 'fullScreenCenterBtn',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _centerToUser,
              child: Icon(
                isTrackingLocation ? Icons.gps_fixed : Icons.my_location,
                color: isTrackingLocation ? Colors.green : Colors.blue,
              ),
            ),
          ),
          if (isTrackingLocation)
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
