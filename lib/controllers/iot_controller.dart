import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../models/iot_data_model.dart';
import '../models/evacuation_model.dart'; // ✅ TAMBAHKAN INI

class FirebaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // IoT Data Observables
  final RxList<IoTData> iotDevices = <IoTData>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  // ✅ Evacuation Points Observables
  final RxList<EvacuationPoint> evacuationPoints = <EvacuationPoint>[].obs;
  final RxBool isLoadingEvacuation = true.obs;

  @override
  void onInit() {
    super.onInit();
    _setupFirebaseMessaging();
    listenToIoTDataWithImages();
    listenToEvacuationPoints(); // ✅ TAMBAHKAN INI
  }

  Future<void> _setupFirebaseMessaging() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');

      String? token = await _messaging.getToken();
      print('📱 FCM Token: $token');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📨 Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          _showNotification(
            message.notification!.title ?? 'Alert',
            message.notification!.body ?? '',
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📲 A new onMessageOpenedApp event was published!');
      });
    }
  }

  void _showNotification(String title, String body) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      icon: const Icon(Icons.warning_amber, color: Colors.white),
      shouldIconPulse: true,
    );
  }

  Future<String?> getLatestDisasterImage(String deviceId) async {
    try {
      final ListResult result = await _storage
          .ref('disaster_images')
          .list(ListOptions(maxResults: 100));

      final matchingFiles =
          result.items.where((ref) {
            return ref.name.startsWith(deviceId);
          }).toList();

      if (matchingFiles.isEmpty) {
        print('📷 No disaster images found for $deviceId');
        return null;
      }

      matchingFiles.sort((a, b) => b.name.compareTo(a.name));

      final downloadUrl = await matchingFiles.first.getDownloadURL();
      print('✅ Found disaster image for $deviceId: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error getting disaster image: $e');
      return null;
    }
  }

  void listenToIoTDataWithImages() {
    try {
      _firestore
          .collection('IOT')
          .snapshots()
          .listen(
            (QuerySnapshot snapshot) async {
              isLoading.value = true;
              error.value = '';

              List<IoTData> devices = [];

              for (var doc in snapshot.docs) {
                try {
                  final data = doc.data() as Map<String, dynamic>;

                  print('=== PARSING DOCUMENT: ${doc.id} ===');
                  print('📋 Raw data keys: ${data.keys.join(", ")}');

                  var iotData = IoTData.fromFirestoreStandard(data);

                  print('✅ Parsed IoTData:');
                  print('   - id: ${iotData.id}');
                  print('   - iotStatus: ${iotData.iotStatus}');
                  print('   - temperature: ${iotData.temperature}');
                  print('   - disasterType: ${iotData.disasterType}');

                  if (iotData.disasterType != null) {
                    print('🚨 Disaster detected, fetching image...');
                    final imageUrl = await getLatestDisasterImage(iotData.id);

                    if (imageUrl != null) {
                      iotData = iotData.copyWith(disasterImageUrl: imageUrl);
                      print('📸 Image URL added: $imageUrl');
                    }
                  }

                  devices.add(iotData);

                  print('✅ Successfully parsed: ${iotData.id}');
                  print('==============================\n');

                  _checkForDisaster(iotData);
                } catch (e, stackTrace) {
                  print('❌ Error parsing document ${doc.id}: $e');
                  print('Stack trace: $stackTrace');
                }
              }

              iotDevices.value = devices;
              isLoading.value = false;

              print('✅ Updated IoT devices: ${devices.length} devices');
            },
            onError: (error) {
              print('❌ Error listening to IoT data: $error');
              this.error.value = error.toString();
              isLoading.value = false;
            },
          );
    } catch (e) {
      print('❌ Error setting up listener: $e');
      error.value = e.toString();
      isLoading.value = false;
    }
  }

  // ✅ LISTEN TO EVACUATION POINTS
  void listenToEvacuationPoints() {
    try {
      _firestore
          .collection('evacuation')
          .snapshots()
          .listen(
            (QuerySnapshot snapshot) {
              isLoadingEvacuation.value = true;

              List<EvacuationPoint> points = [];

              for (var doc in snapshot.docs) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  print('=== PARSING EVACUATION: ${doc.id} ===');
                  print('📋 Raw data: $data');

                  final evacPoint = EvacuationPoint.fromFirestore(data);
                  points.add(evacPoint);

                  print('✅ Parsed evacuation point: ${evacPoint.namaLokasi}');
                  print(
                    '   - Location: ${evacPoint.latitude}, ${evacPoint.longitude}',
                  );
                  print('==============================\n');
                } catch (e, stackTrace) {
                  print('❌ Error parsing evacuation ${doc.id}: $e');
                  print('Stack trace: $stackTrace');
                }
              }

              evacuationPoints.value = points;
              isLoadingEvacuation.value = false;

              print('✅ Updated evacuation points: ${points.length} points');
            },
            onError: (error) {
              print('❌ Error listening to evacuation data: $error');
              isLoadingEvacuation.value = false;
            },
          );
    } catch (e) {
      print('❌ Error setting up evacuation listener: $e');
      isLoadingEvacuation.value = false;
    }
  }

  void listenToIoTData() {
    try {
      _firestore
          .collection('IOT')
          .snapshots()
          .listen(
            (QuerySnapshot snapshot) {
              isLoading.value = true;
              error.value = '';

              List<IoTData> devices = [];

              for (var doc in snapshot.docs) {
                try {
                  final data = doc.data() as Map<String, dynamic>;

                  print('=== PARSING DOCUMENT: ${doc.id} ===');

                  final iotData = IoTData.fromFirestoreStandard(data);
                  devices.add(iotData);

                  print('✅ Parsed: ${iotData.toString()}');
                  print('==============================\n');

                  _checkForDisaster(iotData);
                } catch (e) {
                  print('❌ Error parsing document ${doc.id}: $e');
                }
              }

              iotDevices.value = devices;
              isLoading.value = false;

              print('✅ Updated IoT devices: ${devices.length} devices');
            },
            onError: (error) {
              print('❌ Error listening to IoT data: $error');
              this.error.value = error.toString();
              isLoading.value = false;
            },
          );
    } catch (e) {
      print('❌ Error setting up listener: $e');
      error.value = e.toString();
      isLoading.value = false;
    }
  }

  Stream<IoTData?> listenToDevice(String deviceId) {
    return _firestore.collection('IOT').doc(deviceId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        print('❌ Device $deviceId not found');
        return null;
      }

      try {
        final data = snapshot.data() as Map<String, dynamic>;
        print('✅ Listening to device $deviceId');
        return IoTData.fromFirestoreStandard(data);
      } catch (e) {
        print('❌ Error parsing device $deviceId: $e');
        return null;
      }
    });
  }

  void _checkForDisaster(IoTData data) {
    final disaster = data.disasterType;

    if (disaster != null) {
      String title = '';
      String body = data.statusMessage;

      switch (disaster) {
        case DisasterType.earthquake:
          title = '⚠️ PERINGATAN GEMPA';
          break;
        case DisasterType.flood:
          title = '⚠️ PERINGATAN BANJIR';
          break;
        case DisasterType.fire:
          title = '⚠️ PERINGATAN KEBAKARAN';
          break;
        case DisasterType.earthquakeFlood:
          title = '🚨 PERINGATAN GEMPA & BANJIR';
          break;
        case DisasterType.earthquakeFire:
          title = '🚨 PERINGATAN GEMPA & KEBAKARAN';
          break;
        case DisasterType.floodFire:
          title = '🚨 PERINGATAN BANJIR & KEBAKARAN';
          break;
        case DisasterType.multiple:
          title = '🚨 BENCANA MAJEMUK - EVAKUASI!';
          break;
      }

      print('🚨 DISASTER DETECTED: $title - $body');
      _showNotification(title, '$body - Lokasi: ${data.id}');
    } else {
      print('✅ ${data.id}: ${data.iotStatus} - Kondisi Aman');
    }
  }

  Future<IoTData?> getDeviceData(String deviceId) async {
    try {
      final doc = await _firestore.collection('IOT').doc(deviceId).get();

      if (!doc.exists) {
        print('❌ Device $deviceId not found');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      print('✅ Fetched device $deviceId');
      return IoTData.fromFirestoreStandard(data);
    } catch (e) {
      print('❌ Error getting device data: $e');
      return null;
    }
  }

  Future<List<IoTData>> getAllDevices() async {
    try {
      final snapshot = await _firestore.collection('IOT').get();

      List<IoTData> devices = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final iotData = IoTData.fromFirestoreStandard(data);
          devices.add(iotData);
        } catch (e) {
          print('❌ Error parsing document ${doc.id}: $e');
        }
      }

      print('✅ Fetched ${devices.length} devices');
      return devices;
    } catch (e) {
      print('❌ Error getting all devices: $e');
      return [];
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  // ===== IoT DEVICES HELPER METHODS =====

  List<IoTData> getDevicesInRadius(
    double userLat,
    double userLng,
    double radiusKm,
  ) {
    return iotDevices.where((device) {
      final distance = _calculateDistance(
        userLat,
        userLng,
        device.latitude,
        device.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  Map<String, dynamic> getDeviceStatistics() {
    int totalDevices = iotDevices.length;
    int safeDevices = 0;
    int alertDevices = 0;
    int earthquakeDevices = 0;
    int floodDevices = 0;
    int fireDevices = 0;
    int multipleDisasterDevices = 0;

    for (var device in iotDevices) {
      if (device.disasterType == null) {
        safeDevices++;
      } else {
        alertDevices++;

        switch (device.disasterType) {
          case DisasterType.earthquake:
            earthquakeDevices++;
            break;
          case DisasterType.flood:
            floodDevices++;
            break;
          case DisasterType.fire:
            fireDevices++;
            break;
          case DisasterType.earthquakeFlood:
          case DisasterType.earthquakeFire:
          case DisasterType.floodFire:
          case DisasterType.multiple:
            multipleDisasterDevices++;
            break;
          default:
            break;
        }
      }
    }

    return {
      'total': totalDevices,
      'safe': safeDevices,
      'alert': alertDevices,
      'earthquake': earthquakeDevices,
      'flood': floodDevices,
      'fire': fireDevices,
      'multiple': multipleDisasterDevices,
    };
  }

  List<IoTData> getDevicesByStatus(String status) {
    return iotDevices.where((device) {
      return device.iotStatus.toLowerCase().contains(status.toLowerCase());
    }).toList();
  }

  List<IoTData> getDevicesWithValidGPS() {
    return iotDevices.where((device) => device.gpsValid).toList();
  }

  List<IoTData> getDevicesWithAlert() {
    return iotDevices.where((device) => device.disasterType != null).toList();
  }

  // ===== ✅ EVACUATION POINTS HELPER METHODS =====

  /// Get evacuation points within radius
  List<EvacuationPoint> getEvacuationPointsInRadius(
    double userLat,
    double userLng,
    double radiusKm,
  ) {
    return evacuationPoints.where((point) {
      final distance = _calculateDistance(
        userLat,
        userLng,
        point.latitude,
        point.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Get nearest evacuation point from user location
  EvacuationPoint? getNearestEvacuationPoint(double userLat, double userLng) {
    if (evacuationPoints.isEmpty) return null;

    EvacuationPoint? nearest;
    double minDistance = double.infinity;

    for (var point in evacuationPoints) {
      final distance = _calculateDistance(
        userLat,
        userLng,
        point.latitude,
        point.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = point;
      }
    }

    return nearest;
  }

  /// Get distance to specific evacuation point (in km)
  double getDistanceToEvacuationPoint(
    double userLat,
    double userLng,
    EvacuationPoint point,
  ) {
    return _calculateDistance(
      userLat,
      userLng,
      point.latitude,
      point.longitude,
    );
  }

  /// Get all evacuation points sorted by distance
  List<EvacuationPoint> getEvacuationPointsSortedByDistance(
    double userLat,
    double userLng,
  ) {
    final pointsWithDistance =
        evacuationPoints.map((point) {
          final distance = _calculateDistance(
            userLat,
            userLng,
            point.latitude,
            point.longitude,
          );
          return {'point': point, 'distance': distance};
        }).toList();

    pointsWithDistance.sort((a, b) {
      return (a['distance'] as double).compareTo(b['distance'] as double);
    });

    return pointsWithDistance
        .map((item) => item['point'] as EvacuationPoint)
        .toList();
  }

  /// Get evacuation points by province
  List<EvacuationPoint> getEvacuationPointsByProvince(String province) {
    return evacuationPoints.where((point) {
      return point.evacProv.toLowerCase().contains(province.toLowerCase());
    }).toList();
  }

  /// Get evacuation points by city
  List<EvacuationPoint> getEvacuationPointsByCity(String city) {
    return evacuationPoints.where((point) {
      return point.lokasiKota.toLowerCase().contains(city.toLowerCase());
    }).toList();
  }

  // ===== UTILITY METHODS =====

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }
}
