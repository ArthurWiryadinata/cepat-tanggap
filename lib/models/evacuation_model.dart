import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class EvacuationPoint {
  final String id;
  final String namaLokasi;
  final String lokasiKota;
  final String deskripsiLokasi;
  final double latitude;
  final double longitude;
  final String evacProv;
  final String? gambarLokasi;

  EvacuationPoint({
    required this.id,
    required this.namaLokasi,
    required this.lokasiKota,
    required this.deskripsiLokasi,
    required this.latitude,
    required this.longitude,
    required this.evacProv,
    this.gambarLokasi,
  });

  factory EvacuationPoint.fromFirestore(Map<String, dynamic> data) {
    try {
      // Parse location dari GeoPoint
      double lat = -6.2088; // Default Jakarta
      double lng = 106.8456;

      if (data['location'] != null) {
        if (data['location'] is GeoPoint) {
          final geoPoint = data['location'] as GeoPoint;
          lat = geoPoint.latitude;
          lng = geoPoint.longitude;
        } else if (data['location'] is List) {
          // Format array [lat, lng]
          final location = data['location'] as List;
          if (location.length >= 2) {
            lat = (location[0] is num) ? location[0].toDouble() : lat;
            lng = (location[1] is num) ? location[1].toDouble() : lng;
          }
        }
      }

      return EvacuationPoint(
        id: data['id'] ?? 'Unknown',
        namaLokasi: data['namaLokasi'] ?? 'Titik Evakuasi',
        lokasiKota: data['lokasiKota'] ?? 'Jakarta Barat',
        deskripsiLokasi:
            data['deskripsiLokasi'] ?? 'Parkiran depan, area terbuka luas',
        latitude: lat,
        longitude: lng,
        evacProv: data['evacProv'] ?? 'DKI Jakarta',
        gambarLokasi: data['gambarLokasi'],
      );
    } catch (e) {
      print('Error parsing EvacuationPoint: $e');
      return EvacuationPoint(
        id: data['id'] ?? 'Unknown',
        namaLokasi: 'Titik Evakuasi',
        lokasiKota: 'Jakarta Barat',
        deskripsiLokasi: 'Parkiran depan, area terbuka luas',
        latitude: -6.2088,
        longitude: 106.8456,
        evacProv: 'DKI Jakarta',
      );
    }
  }

  LatLng get position => LatLng(latitude, longitude);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaLokasi': namaLokasi,
      'lokasiKota': lokasiKota,
      'deskripsiLokasi': deskripsiLokasi,
      'latitude': latitude,
      'longitude': longitude,
      'evacProv': evacProv,
      'gambarLokasi': gambarLokasi,
    };
  }

  @override
  String toString() {
    return 'EvacuationPoint(id: $id, nama: $namaLokasi, lat: $latitude, lng: $longitude)';
  }
}
