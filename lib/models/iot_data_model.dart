import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

// ❌ HAPUS CLASS INI - Tidak ada threshold checking di Flutter
// class SensorThresholds { ... }

class IoTData {
  final String id;
  final double latitude;
  final double longitude;
  final double waterLevel;
  final double earthquakeIntensity;
  final double temperature;
  final double humidity;
  final String iotStatus;
  final bool gpsValid;
  final int satellites;
  final DateTime lastUpdated;
  final String? disasterImageUrl;

  IoTData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.waterLevel,
    required this.earthquakeIntensity,
    required this.temperature,
    required this.humidity,
    required this.iotStatus,
    required this.gpsValid,
    required this.satellites,
    required this.lastUpdated,
    this.disasterImageUrl,
  });

  factory IoTData.fromFirestoreStandard(Map<String, dynamic> data) {
    try {
      print('🔍 === PARSING IoT DATA ===');
      print('Raw Firebase data: $data');

      // Parse location (GeoPoint)
      double lat = -6.2088;
      double lng = 106.8456;

      if (data['location'] != null) {
        if (data['location'] is GeoPoint) {
          final geoPoint = data['location'] as GeoPoint;
          lat = geoPoint.latitude;
          lng = geoPoint.longitude;
        }
      }

      // Parse sensorData map
      double temp = 0.0;
      double humidity = 0.0;
      double waterLevel = 0.0;
      double eqIntensity = 0.0;

      if (data['sensorData'] != null && data['sensorData'] is Map) {
        final sensorMap = data['sensorData'] as Map<String, dynamic>;
        temp = (sensorMap['temperature'] ?? 0).toDouble();
        humidity = (sensorMap['humidity'] ?? 0).toDouble();
        waterLevel = (sensorMap['waterLevel'] ?? 0).toDouble();
        eqIntensity = (sensorMap['earthquakeIntensity'] ?? 0).toDouble();

        print('📊 Sensor data parsed:');
        print('   - temp: $temp');
        print('   - humidity: $humidity');
        print('   - waterLevel: $waterLevel');
        print('   - eqIntensity: $eqIntensity');
      }

      // ✅ HANYA BACA IOTStatus dari Firebase - NO LOGIC
      String iotStatus = 'is safe'; // Default

      // PRIORITAS 1: Ambil IOTStatus langsung (NEW STRUCTURE)
      if (data['IOTStatus'] != null) {
        iotStatus = data['IOTStatus'].toString().trim();
        print('✅ Found IOTStatus (root level): "$iotStatus"');
      }
      // PRIORITAS 2: Cek di dalam disasterStatus map (OLD STRUCTURE)
      else if (data['disasterStatus'] != null &&
          data['disasterStatus'] is Map) {
        final disasterMap = data['disasterStatus'] as Map<String, dynamic>;
        if (disasterMap['IOTStatus'] != null) {
          iotStatus = disasterMap['IOTStatus'].toString().trim();
          print('✅ Found IOTStatus (disasterStatus map): "$iotStatus"');
        }
      }

      print('📝 FINAL IOTStatus: "$iotStatus"');

      // Parse gpsInfo map
      bool gpsValid = false;
      int satellites = 0;

      if (data['gpsInfo'] != null && data['gpsInfo'] is Map) {
        final gpsMap = data['gpsInfo'] as Map<String, dynamic>;
        gpsValid = gpsMap['valid'] ?? false;
        satellites =
            (gpsMap['satellites'] ?? 0) is String
                ? int.tryParse(gpsMap['satellites']) ?? 0
                : (gpsMap['satellites'] ?? 0);
      }

      // Parse lastUpdated (Timestamp)
      DateTime lastUpdated = DateTime.now();
      if (data['lastUpdated'] != null) {
        if (data['lastUpdated'] is Timestamp) {
          lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
        }
      }

      // Parse disaster image URL
      String? imageUrl;
      if (data['disasterImageUrl'] != null) {
        imageUrl = data['disasterImageUrl'] as String;
      }

      final result = IoTData(
        id: data['id'] ?? 'Unknown',
        latitude: lat,
        longitude: lng,
        waterLevel: waterLevel,
        earthquakeIntensity: eqIntensity,
        temperature: temp,
        humidity: humidity,
        iotStatus: iotStatus,
        gpsValid: gpsValid,
        satellites: satellites,
        lastUpdated: lastUpdated,
        disasterImageUrl: imageUrl,
      );

      print('✅ Successfully created IoTData:');
      print('   - id: ${result.id}');
      print('   - iotStatus: "${result.iotStatus}"');
      print('   - disasterType: ${result.disasterType}');
      print('==================\n');

      return result;
    } catch (e, stackTrace) {
      print('❌ Error parsing IoTData: $e');
      print('Stack trace: $stackTrace');
      return IoTData(
        id: data['id'] ?? 'Unknown',
        latitude: -6.2088,
        longitude: 106.8456,
        waterLevel: 0,
        earthquakeIntensity: 0,
        temperature: 0,
        humidity: 0,
        iotStatus: 'is safe',
        gpsValid: false,
        satellites: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  LatLng get position => LatLng(latitude, longitude);

  // ✅ DISEDERHANAKAN: Getter disaster type - PURE dari iotStatus
  DisasterType? get disasterType {
    final status = iotStatus.toLowerCase().trim();

    print('🔍 Checking disasterType for status: "$status"');

    // SAFE status
    if (status == 'is safe' || status == 'safe' || status.isEmpty) {
      print('   → Result: null (safe)');
      return null;
    }

    // ✅ EXACT MATCHES (sesuai yang dikirim ESP32)
    if (status == 'gempa') {
      print('   → Result: DisasterType.earthquake');
      return DisasterType.earthquake;
    }
    if (status == 'banjir') {
      print('   → Result: DisasterType.flood');
      return DisasterType.flood;
    }
    if (status == 'kebakaran') {
      print('   → Result: DisasterType.fire');
      return DisasterType.fire;
    }

    // CONTAINS CHECKS (untuk status kombinasi dari ESP32)
    bool hasGempa = status.contains('gempa');
    bool hasBanjir = status.contains('banjir');
    bool hasKebakaran = status.contains('kebakaran') || status.contains('api');

    // Count disasters
    int disasterCount =
        [hasGempa, hasBanjir, hasKebakaran].where((d) => d).length;

    print(
      '   → hasGempa: $hasGempa, hasBanjir: $hasBanjir, hasKebakaran: $hasKebakaran',
    );

    if (disasterCount >= 3) {
      print('   → Result: DisasterType.multiple');
      return DisasterType.multiple;
    }

    // Check combinations
    if (hasGempa && hasBanjir) {
      print('   → Result: DisasterType.earthquakeFlood');
      return DisasterType.earthquakeFlood;
    }
    if (hasGempa && hasKebakaran) {
      print('   → Result: DisasterType.earthquakeFire');
      return DisasterType.earthquakeFire;
    }
    if (hasBanjir && hasKebakaran) {
      print('   → Result: DisasterType.floodFire');
      return DisasterType.floodFire;
    }

    // Single disasters
    if (hasGempa) {
      print('   → Result: DisasterType.earthquake');
      return DisasterType.earthquake;
    }
    if (hasBanjir) {
      print('   → Result: DisasterType.flood');
      return DisasterType.flood;
    }
    if (hasKebakaran) {
      print('   → Result: DisasterType.fire');
      return DisasterType.fire;
    }

    // ✅ Jika status tidak dikenali, anggap safe
    print('   → Result: null (unrecognized status, assume safe)');
    return null;
  }

  String get statusMessage {
    final disaster = disasterType;

    if (disaster == null) {
      return 'Kondisi Normal - Aman';
    }

    switch (disaster) {
      case DisasterType.earthquake:
        return 'GEMPA TERDETEKSI! Intensitas: ${earthquakeIntensity.toStringAsFixed(1)}';

      case DisasterType.flood:
        return 'BANJIR TERDETEKSI! Ketinggian: ${waterLevel.toStringAsFixed(0)} cm';

      case DisasterType.fire:
        return 'KEBAKARAN TERDETEKSI! Suhu: ${temperature.toStringAsFixed(1)}°C';

      case DisasterType.earthquakeFlood:
        return 'GEMPA & BANJIR! Evakuasi Segera!';

      case DisasterType.earthquakeFire:
        return 'GEMPA & KEBAKARAN! Bahaya Tinggi!';

      case DisasterType.floodFire:
        return 'BANJIR & KEBAKARAN! Evakuasi Segera!';

      case DisasterType.multiple:
        return 'BENCANA MAJEMUK! EVAKUASI DARURAT!';
    }
  }

  String get severity {
    final disaster = disasterType;
    if (disaster == null) return 'safe';

    switch (disaster) {
      case DisasterType.multiple:
      case DisasterType.earthquakeFlood:
      case DisasterType.earthquakeFire:
      case DisasterType.floodFire:
        return 'critical';
      case DisasterType.fire:
        return 'high';
      case DisasterType.earthquake:
        return 'medium';
      case DisasterType.flood:
        return 'medium';
    }
  }

  String get sensorSummary {
    return '''
Suhu: ${temperature.toStringAsFixed(1)}°C
Kelembaban: ${humidity.toStringAsFixed(0)}%
Ketinggian Air: ${waterLevel.toStringAsFixed(0)} cm
Intensitas Gempa: ${earthquakeIntensity.toStringAsFixed(1)}
''';
  }

  IoTData copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? waterLevel,
    double? earthquakeIntensity,
    double? temperature,
    double? humidity,
    String? iotStatus,
    bool? gpsValid,
    int? satellites,
    DateTime? lastUpdated,
    String? disasterImageUrl,
  }) {
    return IoTData(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      waterLevel: waterLevel ?? this.waterLevel,
      earthquakeIntensity: earthquakeIntensity ?? this.earthquakeIntensity,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      iotStatus: iotStatus ?? this.iotStatus,
      gpsValid: gpsValid ?? this.gpsValid,
      satellites: satellites ?? this.satellites,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      disasterImageUrl: disasterImageUrl ?? this.disasterImageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'waterLevel': waterLevel,
      'earthquakeIntensity': earthquakeIntensity,
      'temperature': temperature,
      'humidity': humidity,
      'iotStatus': iotStatus,
      'gpsValid': gpsValid,
      'satellites': satellites,
      'lastUpdated': lastUpdated.toIso8601String(),
      'disasterImageUrl': disasterImageUrl,
      'disasterType': disasterType?.toString(),
      'statusMessage': statusMessage,
      'severity': severity,
      'sensorSummary': sensorSummary,
    };
  }

  @override
  String toString() {
    return 'IoTData(id: $id, iotStatus: "$iotStatus", disasterType: $disasterType, lat: $latitude, lng: $longitude)';
  }
}

enum DisasterType {
  earthquake,
  flood,
  fire,
  earthquakeFlood,
  earthquakeFire,
  floodFire,
  multiple,
}
