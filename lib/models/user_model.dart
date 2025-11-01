import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String userName;
  final String userEmail;
  final String golDarah;
  final String penyakitBawaan;
  final String alergiObat;
  final String userAlamat;
  final String userPhone;
  final String userProvince;
  final String userKota;
  final String userSex;
  final String userFCM;
  final GeoPoint userLocation;
  final Timestamp? createdAt;
  final Timestamp? lastUpdated;

  UserModel({
    this.id,
    required this.userName,
    required this.userEmail,
    required this.golDarah,
    required this.penyakitBawaan,
    required this.alergiObat,
    required this.userAlamat,
    required this.userPhone,
    required this.userProvince,
    required this.userKota,
    required this.userSex,
    required this.userFCM,
    required this.userLocation,
    this.createdAt,
    this.lastUpdated,
  });

  /// 🔹 Convert Firestore Document → UserModel
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      golDarah: data['golDarah'] ?? '',
      penyakitBawaan: data['penyakitBawaan'] ?? '-',
      alergiObat: data['alergiObat'] ?? '-',
      userAlamat: data['userAlamat'] ?? '-',
      userPhone: data['userPhone'] ?? '',
      userProvince: data['userProvince'] ?? '',
      userKota: data['userKota'] ?? '',
      userSex: data['userSex'] ?? '',
      userFCM: data['userFCM'] ?? '',
      userLocation: data['userLocation'] ?? const GeoPoint(0, 0),
      createdAt: data['createdAt'],
      lastUpdated: data['lastUpdated'],
    );
  }

  /// 🔹 Convert UserModel → Map (untuk disimpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'golDarah': golDarah,
      'penyakitBawaan': penyakitBawaan,
      'alergiObat': alergiObat,
      'userAlamat': userAlamat,
      'userPhone': userPhone,
      'userProvince': userProvince,
      'userKota': userKota,
      'userSex': userSex,
      'userFCM': userFCM,
      'userLocation': userLocation,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
    };
  }
}
