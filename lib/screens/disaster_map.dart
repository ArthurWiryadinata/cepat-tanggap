import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/iot_controller.dart';
import '../models/iot_data_model.dart';
import '../models/evacuation_model.dart';

class DisasterMapWidget extends StatefulWidget {
  final Function(bool)? onDisasterDetected;

  const DisasterMapWidget({super.key, this.onDisasterDetected});

  @override
  State<DisasterMapWidget> createState() => _DisasterMapWidgetState();
}

class _DisasterMapWidgetState extends State<DisasterMapWidget>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final FirebaseService _firebaseService;
  late AnimationController _animationController;

  LatLng userLocation = LatLng(-6.2088, 106.8456);
  bool isLoadingLocation = true;
  bool showEvacuationPoints = false;

  // ✅ Real-time GPS tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  bool isTrackingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    try {
      _firebaseService = Get.find<FirebaseService>();
    } catch (e) {
      _firebaseService = Get.put(FirebaseService(), permanent: true);
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _getUserLocation();
    _firebaseService.listenToEvacuationPoints();

    // ✅ Start real-time tracking
    _startLocationTracking();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // ✅ Real-time GPS Tracking
  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => isLoadingLocation = false);
        return;
      }

      // ✅ Start streaming location updates
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update setiap 10 meter
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            userLocation = LatLng(position.latitude, position.longitude);
            isLoadingLocation = false;
            isTrackingLocation = true;
          });

          // Auto-center map ke user location
          _mapController.move(userLocation, _mapController.camera.zoom);

          // Check disaster in new location
          _checkDisasterInRadius();
        }
      });
    } catch (e) {
      if (mounted) setState(() => isLoadingLocation = false);
      print('Error starting location tracking: $e');
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
          isLoadingLocation = false;
        });
        _mapController.move(userLocation, 13.0);
        _checkDisasterInRadius();
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingLocation = false);
      print('Error getting location: $e');
    }
  }

  // ✅ Check disaster dalam radius dan trigger callback
  void _checkDisasterInRadius() {
    final devicesInRadius = _firebaseService.getDevicesInRadius(
      userLocation.latitude,
      userLocation.longitude,
      5.0,
    );

    final hasDisaster = devicesInRadius.any((d) => d.disasterType != null);

    if (widget.onDisasterDetected != null) {
      widget.onDisasterDetected!(hasDisaster);
    }
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
      default:
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
      default:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ✅ CEK APAKAH ADA DISASTER DALAM RADIUS 5KM
      final devicesInRadius = _firebaseService.getDevicesInRadius(
        userLocation.latitude,
        userLocation.longitude,
        5.0,
      );
      final hasDisaster = devicesInRadius.any((d) => d.disasterType != null);

      // ✅ JIKA TIDAK ADA DISASTER, RETURN EMPTY WIDGET (HIDE)
      if (!hasDisaster) {
        return SizedBox.shrink(); // Widget tersembunyi
      }

      // ✅ JIKA ADA DISASTER, TAMPILKAN WIDGET
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey, width: 0.2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0.1,
              blurRadius: 6,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Lokasi Terdampak",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          if (isTrackingLocation) ...[
                            SizedBox(width: 8),
                            Icon(
                              Icons.gps_fixed,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        "Radius 5 km dari lokasi Anda",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          showEvacuationPoints
                              ? Icons.location_on
                              : Icons.location_off,
                          color:
                              showEvacuationPoints ? Colors.green : Colors.grey,
                        ),
                        onPressed: () {
                          setState(
                            () => showEvacuationPoints = !showEvacuationPoints,
                          );
                        },
                        tooltip:
                            showEvacuationPoints
                                ? 'Sembunyikan Titik Evakuasi'
                                : 'Tampilkan Titik Evakuasi',
                      ),
                      if (isLoadingLocation)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildMapContainer(),
              SizedBox(height: 12),
              _buildDisasterStatus(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMapContainer() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Obx(() {
          final devicesInRadius = _firebaseService.getDevicesInRadius(
            userLocation.latitude,
            userLocation.longitude,
            5.0,
          );
          final evacuationInRadius =
              showEvacuationPoints
                  ? _firebaseService.getEvacuationPointsInRadius(
                    userLocation.latitude,
                    userLocation.longitude,
                    5.0,
                  )
                  : <EvacuationPoint>[];
          final hasDisaster = devicesInRadius.any(
            (d) => d.disasterType != null,
          );

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLocation,
                  initialZoom: 13.0,
                  minZoom: 10.0,
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
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: userLocation,
                        radius: 5000,
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.1),
                        borderColor: Colors.blue.withOpacity(0.3),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  if (hasDisaster)
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return CircleLayer(
                          circles:
                              devicesInRadius
                                  .where((d) => d.disasterType != null)
                                  .map((device) {
                                    final scale =
                                        1.0 +
                                        (_animationController.value * 0.5);
                                    final opacity =
                                        1.0 - _animationController.value;
                                    return CircleMarker(
                                      point: device.position,
                                      radius: 30 * scale,
                                      useRadiusInMeter: false,
                                      color: _getColorForDevice(
                                        device,
                                      ).withOpacity(0.3 * opacity),
                                      borderColor: _getColorForDevice(
                                        device,
                                      ).withOpacity(0.6 * opacity),
                                      borderStrokeWidth: 2,
                                    );
                                  })
                                  .toList(),
                        );
                      },
                    ),
                  if (showEvacuationPoints && evacuationInRadius.isNotEmpty)
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return CircleLayer(
                          circles:
                              evacuationInRadius.map((point) {
                                final scale =
                                    1.0 + (_animationController.value * 0.3);
                                final opacity =
                                    1.0 - _animationController.value;
                                return CircleMarker(
                                  point: point.position,
                                  radius: 25 * scale,
                                  useRadiusInMeter: false,
                                  color: Colors.green.withOpacity(
                                    0.2 * opacity,
                                  ),
                                  borderColor: Colors.green.withOpacity(
                                    0.5 * opacity,
                                  ),
                                  borderStrokeWidth: 2,
                                );
                              }).toList(),
                        );
                      },
                    ),
                  MarkerLayer(
                    markers: [
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
                      ...devicesInRadius.map(
                        (device) => Marker(
                          point: device.position,
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () => _showDisasterDetail(context, device),
                            child: Icon(
                              _getIconForDevice(device),
                              color: _getColorForDevice(device),
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      if (showEvacuationPoints)
                        ...evacuationInRadius.map(
                          (point) => Marker(
                            point: point.position,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap:
                                  () => _showEvacuationDetailSheet(
                                    context,
                                    point,
                                  ),
                              child: Stack(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                    size: 40,
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 10,
                                    child: Icon(
                                      Icons.emergency,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 8,
                bottom: 60,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'zoomIn',
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          currentZoom + 1,
                        );
                      },
                      child: Icon(Icons.add, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'zoomOut',
                      mini: true,
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          currentZoom - 1,
                        );
                      },
                      child: Icon(Icons.remove, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${devicesInRadius.where((d) => d.disasterType != null).length} bencana terdeteksi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showEvacuationPoints && evacuationInRadius.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4),
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
                              Icons.emergency,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${evacuationInRadius.length} titik evakuasi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDisasterStatus() {
    return Obx(() {
      final devicesInRadius = _firebaseService.getDevicesInRadius(
        userLocation.latitude,
        userLocation.longitude,
        5.0,
      );
      final disasterDevices =
          devicesInRadius.where((d) => d.disasterType != null).toList();

      final nearestEvacuation = _firebaseService.getNearestEvacuationPoint(
        userLocation.latitude,
        userLocation.longitude,
      );

      return Column(
        children: [
          GestureDetector(
            onTap: () => _showDisasterDetail(context, disasterDevices.first),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.dangerous, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Darurat',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${disasterDevices.length} lokasi terdampak - Tap untuk detail',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
          if (nearestEvacuation != null) ...[
            SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => showEvacuationPoints = true);
                _showEvacuationDetailSheet(context, nearestEvacuation);
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emergency, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Titik Evakuasi Terdekat',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${nearestEvacuation.namaLokasi} - ${_firebaseService.getDistanceToEvacuationPoint(userLocation.latitude, userLocation.longitude, nearestEvacuation).toStringAsFixed(2)} km',
                            style: TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  void _showDisasterDetail(BuildContext context, IoTData device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DisasterDetailSheet(device: device),
    );
  }

  void _showEvacuationDetailSheet(BuildContext context, EvacuationPoint point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              EvacuationDetailSheet(point: point, userLocation: userLocation),
    );
  }
}

// ===== EVACUATION DETAIL SHEET =====
class EvacuationDetailSheet extends StatelessWidget {
  final EvacuationPoint point;
  final LatLng userLocation;

  const EvacuationDetailSheet({
    super.key,
    required this.point,
    required this.userLocation,
  });

  double _calculateDistance() {
    const double earthRadius = 6371;
    final dLat = _toRadians(point.latitude - userLocation.latitude);
    final dLon = _toRadians(point.longitude - userLocation.longitude);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(userLocation.latitude)) *
            cos(_toRadians(point.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * (pi / 180);

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency, color: Colors.green, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TITIK EVAKUASI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              point.id,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Text(
                    point.namaLokasi,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(Icons.location_city, 'Kota', point.lokasiKota),
                  _buildInfoRow(Icons.map, 'Provinsi', point.evacProv),
                  _buildInfoRow(
                    Icons.directions,
                    'Jarak',
                    '${distance.toStringAsFixed(2)} km dari lokasi Anda',
                  ),
                  _buildInfoRow(
                    Icons.info_outline,
                    'Deskripsi',
                    point.deskripsiLokasi,
                  ),
                  SizedBox(height: 16),
                  if (point.gambarLokasi != null &&
                      point.gambarLokasi!.isNotEmpty) ...[
                    Text(
                      'Foto Lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        point.gambarLokasi!,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('Gagal memuat gambar'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            print(
                              'Open directions to ${point.namaLokasi} at ${point.latitude}, ${point.longitude}',
                            );
                          },
                          icon: Icon(Icons.directions),
                          label: Text('Petunjuk Arah'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close),
                          label: Text('Tutup'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFFD9D9D9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== DISASTER DETAIL SHEET =====
class DisasterDetailSheet extends StatelessWidget {
  final IoTData device;

  const DisasterDetailSheet({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BENCANA TERDETEKSI',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              device.id,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 16),
                  Text(
                    device.statusMessage,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16),
                  _buildSensorRow(
                    'Suhu',
                    '${device.temperature.toStringAsFixed(1)}°C',
                    Icons.thermostat,
                  ),
                  _buildSensorRow(
                    'Kelembaban',
                    '${device.humidity.toStringAsFixed(0)}%',
                    Icons.water_drop,
                  ),
                  _buildSensorRow(
                    'Ketinggian Air',
                    '${device.waterLevel.toStringAsFixed(0)} cm',
                    Icons.waves,
                  ),
                  if (device.earthquakeIntensity > 0)
                    _buildSensorRow(
                      'Intensitas Gempa',
                      device.earthquakeIntensity.toStringAsFixed(1),
                      Icons.warning_amber,
                    ),
                  SizedBox(height: 16),
                  if (device.disasterImageUrl != null) ...[
                    Text(
                      'Foto Lokasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        device.disasterImageUrl!,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text('Gagal memuat gambar'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Diambil oleh ESP32-CAM',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      label: Text('Tutup'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFD9D9D9),
                      ),
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

  Widget _buildSensorRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
