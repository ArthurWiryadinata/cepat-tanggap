import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'iot_controller.dart';
import 'location_controller.dart';

/// ✅ Alert Service - Monitor disasters dan trigger push notifications
/// File terpisah untuk avoid circular dependency dan ambiguous import
class AlertService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late final FirebaseService _firebaseService;
  late final LocationController _locationController;

  final RxBool hasActiveAlert = false.obs;
  final RxString currentAlertDocId = ''.obs;

  // Track alert per device dengan cooldown
  final Map<String, DateTime> _deviceAlertTimes = {};
  final Duration _cooldownDuration = Duration(seconds: 10);

  @override
  void onInit() {
    super.onInit();

    try {
      _firebaseService = Get.find<FirebaseService>();
      print('✅ AlertService: FirebaseService found');
    } catch (e) {
      print('❌ AlertService: Error getting FirebaseService: $e');
      return;
    }

    try {
      _locationController = Get.find<LocationController>();
      print('✅ AlertService: LocationController found');
    } catch (e) {
      print('❌ AlertService: Error getting LocationController: $e');
      return;
    }

    _startMonitoringDisasters();
  }

  void _startMonitoringDisasters() {
    print('📡 AlertService: Start monitoring disasters');

    // Listen setiap perubahan IoT devices
    ever(_firebaseService.iotDevices, (_) {
      print('🔄 AlertService: IoT devices updated');
      _checkAndUpdateAlert();
    });
  }

  /// ✅ MAIN METHOD: Check disaster dalam radius 5km
  /// Dipanggil dari LocationController setiap location update
  Future<void> checkDisasterInRadius(double userLat, double userLng) async {
    try {
      print('\n🔍 ═══ ALERT CHECK START ═══');
      print('📍 User location: $userLat, $userLng');

      final devicesInRadius = _firebaseService.getDevicesInRadius(
        userLat,
        userLng,
        5.0,
      );

      print('📊 Devices in radius 5km: ${devicesInRadius.length}');

      // Filter devices dengan disaster
      final disasterDevices =
          devicesInRadius.where((d) => d.disasterType != null).toList();

      print('🚨 Disaster devices: ${disasterDevices.length}');

      if (disasterDevices.isEmpty) {
        print('✅ No disasters detected - clearing alert if exists');
        if (hasActiveAlert.value) {
          await _clearEmergencyAlert();
        }
        print('═══ ALERT CHECK END (NO DISASTER) ═══\n');
        return;
      }

      // Check per device dengan cooldown
      bool shouldCreateAlert = false;
      final now = DateTime.now();

      for (var device in disasterDevices) {
        final lastAlertTime = _deviceAlertTimes[device.id];

        if (lastAlertTime == null) {
          // Belum pernah alert untuk device ini
          shouldCreateAlert = true;
          _deviceAlertTimes[device.id] = now;
          print('🆕 New disaster detected: ${device.id}');
        } else {
          final timeSinceLastAlert = now.difference(lastAlertTime);
          if (timeSinceLastAlert > _cooldownDuration) {
            // Cooldown expired
            shouldCreateAlert = true;
            _deviceAlertTimes[device.id] = now;
            print('🔄 Cooldown expired for ${device.id}');
          } else {
            print(
              '⏱️ Cooldown active for ${device.id}: ${timeSinceLastAlert.inSeconds}s / ${_cooldownDuration.inSeconds}s',
            );
          }
        }
      }

      if (shouldCreateAlert) {
        print('✅ Creating emergency alert');
        await _createEmergencyAlert(disasterDevices, userLat, userLng);
      } else {
        print('⏸️ All devices in cooldown, skip alert');
      }

      print('═══ ALERT CHECK END ═══\n');
    } catch (e) {
      print('❌ AlertService: Error checking alert: $e');
    }
  }

  /// Internal check (dipanggil saat IoT devices berubah)
  Future<void> _checkAndUpdateAlert() async {
    try {
      final location = _locationController.getLocationOrDefault();
      await checkDisasterInRadius(location.latitude, location.longitude);
    } catch (e) {
      print('⚠️ AlertService: Error in auto-check: $e');
    }
  }

  /// Create emergency alert di Firestore
  Future<void> _createEmergencyAlert(
    List disasterDevices,
    double userLat,
    double userLng,
  ) async {
    try {
      print('\n🚨 ═══ CREATING EMERGENCY ALERT ═══');

      // Hitung disaster counts
      int earthquakeCount =
          disasterDevices
              .where((d) => d.disasterType.toString().contains('earthquake'))
              .length;
      int floodCount =
          disasterDevices
              .where((d) => d.disasterType.toString().contains('flood'))
              .length;
      int fireCount =
          disasterDevices
              .where((d) => d.disasterType.toString().contains('fire'))
              .length;

      List<String> disasterTypes = [];
      if (earthquakeCount > 0) disasterTypes.add('Gempa');
      if (floodCount > 0) disasterTypes.add('Banjir');
      if (fireCount > 0) disasterTypes.add('Kebakaran');

      double nearestDistance = _getNearestDistance(
        disasterDevices,
        userLat,
        userLng,
      );

      String message =
          '${disasterDevices.length} lokasi terdampak dalam radius 5 km: '
          '${disasterTypes.join(', ')}. '
          'Jarak terdekat: ${nearestDistance.toStringAsFixed(2)} km dari lokasi Anda';

      print('📝 Alert message: $message');
      print('📊 Disaster breakdown:');
      print('   - Gempa: $earthquakeCount');
      print('   - Banjir: $floodCount');
      print('   - Kebakaran: $fireCount');

      // Create alert document
      final docRef = await _firestore.collection('alerts').add({
        'type': 'emergency',
        'title': '🚨 BENCANA TERDETEKSI!',
        'message': message,
        'disasterCount': disasterDevices.length,
        'earthquakeCount': earthquakeCount,
        'floodCount': floodCount,
        'fireCount': fireCount,
        'userLat': userLat,
        'userLng': userLng,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceIds': disasterDevices.map((d) => d.id).toList(),
        'disasterTypes': disasterTypes,
        'nearestDistance': nearestDistance,
      });

      hasActiveAlert.value = true;
      currentAlertDocId.value = docRef.id;

      print('✅ Alert document created: ${docRef.id}');
      print('═══ ALERT CREATION END ═══\n');
    } catch (e) {
      print('❌ AlertService: Error creating alert: $e');
    }
  }

  /// Clear emergency alert dari Firestore
  Future<void> _clearEmergencyAlert() async {
    try {
      if (!hasActiveAlert.value) return;

      print('\n🧹 ═══ CLEARING EMERGENCY ALERT ═══');

      if (currentAlertDocId.value.isNotEmpty) {
        await _firestore
            .collection('alerts')
            .doc(currentAlertDocId.value)
            .delete();

        print('✅ Alert cleared: ${currentAlertDocId.value}');
      }

      hasActiveAlert.value = false;
      currentAlertDocId.value = '';
      _deviceAlertTimes.clear();

      print('🧹 Device alert times cleared');
      print('═══ CLEAR ALERT END ═══\n');
    } catch (e) {
      print('❌ AlertService: Error clearing alert: $e');
    }
  }

  /// Get nearest distance dari disaster devices ke user
  double _getNearestDistance(List devices, double userLat, double userLng) {
    double minDistance = double.infinity;

    for (var device in devices) {
      if (device.disasterType == null) continue;

      final distance = _firebaseService.getDistanceToEvacuationPoint(
        userLat,
        userLng,
        device,
      );

      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Manual test method
  Future<void> testEmergencyAlert() async {
    print('🧪 ═══ TESTING EMERGENCY ALERT ═══');

    await _firestore.collection('alerts').add({
      'type': 'emergency',
      'title': '🧪 TEST Emergency Alert',
      'message': 'This is a test alert from AlertService',
      'timestamp': FieldValue.serverTimestamp(),
      'isTest': true,
    });

    print('✅ Test alert sent');
  }

  /// Force refresh alert check
  Future<void> forceCheckAlert() async {
    print('🔄 ═══ FORCE CHECKING ALERT ═══');
    await _checkAndUpdateAlert();
  }
}
