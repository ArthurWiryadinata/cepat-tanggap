import 'dart:async';
import 'package:cepattanggap/widgets/snack_bar_custom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

/// ✅ Location Controller - Track GPS dan trigger alert check
/// AlertService sudah dipindah ke file terpisah (alert_service.dart)
class LocationController extends GetxController {
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  Position? _latestPosition;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final RxBool isLoadingLocation = true.obs;
  final RxBool isTrackingLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    startLocationTracking();
  }

  void startLocationTracking() async {
    final allowed = await _checkPermission();
    if (!allowed) {
      isLoadingLocation.value = false;
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Trigger setiap 5 meter
      ),
    ).listen(
      (position) {
        _latestPosition = position;

        currentLocation.value = LatLng(position.latitude, position.longitude);
        isLoadingLocation.value = false;
        isTrackingLocation.value = true;

        print('\n📍 ═══ LOCATION UPDATE ═══');
        print('Lat: ${position.latitude}');
        print('Lng: ${position.longitude}');
        print('═══ LOCATION END ═══\n');

        // ✅ Trigger alert check setiap location update
        _checkDisasterAlert(position);
      },
      onError: (error) {
        print("❌ Location stream error: $error");
        isTrackingLocation.value = false;
      },
    );

    // Update Firestore setiap 2 detik
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_latestPosition != null) {
        updateLocationToFirestore(_latestPosition!);
      }
    });
  }

  /// ✅ Trigger alert check via AlertService
  Future<void> _checkDisasterAlert(Position position) async {
    try {
      // Get AlertService (dari file terpisah alert_service.dart)
      final alertService = Get.find<dynamic>();

      if (alertService.runtimeType.toString() == 'AlertService') {
        print('🔍 Triggering disaster check via AlertService...');

        // Call method checkDisasterInRadius dari AlertService
        await alertService.checkDisasterInRadius(
          position.latitude,
          position.longitude,
        );

        print('✅ Disaster check completed');
      } else {
        print('⚠️ AlertService type mismatch: ${alertService.runtimeType}');
      }
    } catch (e) {
      print('⚠️ LocationController: AlertService not found: $e');

      // Try to initialize AlertService if not found
      try {
        print('🔄 Attempting to find/initialize AlertService...');
        // AlertService harus sudah di-init di AppBinding (main.dart)
        // Ini fallback untuk edge case
      } catch (initError) {
        print('❌ Cannot initialize AlertService: $initError');
      }
    }
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showAppSnackbar(
        'GPS Tidak Aktif',
        'Silakan aktifkan layanan lokasi',
        isSuccess: false,
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showAppSnackbar(
        'Akses Ditolak',
        'Aktifkan izin lokasi di pengaturan',
        isSuccess: false,
      );
      return false;
    }

    return true;
  }

  Future<void> updateLocationToFirestore(Position pos) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'userLocation': GeoPoint(pos.latitude, pos.longitude),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Helper method untuk mendapatkan lokasi atau default
  LatLng getLocationOrDefault() {
    if (currentLocation.value != null) {
      return currentLocation.value!;
    }

    if (_latestPosition != null) {
      return LatLng(_latestPosition!.latitude, _latestPosition!.longitude);
    }

    // Default Jakarta
    return LatLng(-6.2088, 106.8456);
  }

  /// Get current position synchronously
  Position? get currentPosition => _latestPosition;

  /// Manual trigger untuk testing
  Future<void> forceCheckDisaster() async {
    if (_latestPosition != null) {
      print('🔄 Force checking disaster...');
      await _checkDisasterAlert(_latestPosition!);
    } else {
      print('⚠️ No position available for disaster check');
    }
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.onClose();
  }
}
