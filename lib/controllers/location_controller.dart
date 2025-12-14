import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationController extends GetxController {
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  Position? _latestPosition;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    startLocationTracking();
  }

  void startLocationTracking() async {
    final allowed = await _checkPermission();
    if (!allowed) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (position) {
        _latestPosition = position;
      },
      onError: (error) {
        print("❌ Location stream error: $error");
      },
    );

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_latestPosition != null) {
        updateLocationToFirestore(_latestPosition!);
      }
    });
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('GPS Tidak Aktif', 'Silakan aktifkan layanan lokasi');
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
      Get.snackbar('Permission Ditolak', 'Aktifkan izin lokasi di pengaturan');
      return false;
    }

    return true;
  }

  Future<void> updateLocationToFirestore(Position pos) async {
    final user = _auth.currentUser;
    if (user == null) return;

    print("data update");
    await _firestore.collection('users').doc(user.uid).update({
      'userLocation': GeoPoint(pos.latitude, pos.longitude),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.onClose();
  }
}
