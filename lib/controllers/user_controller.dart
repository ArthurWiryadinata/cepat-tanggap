import 'package:cepattanggap/models/user_model.dart';
import 'package:cepattanggap/screens/main_page.dart';
import 'package:cepattanggap/widgets/snack_bar_custom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // ⬅️ Tambahkan ini
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class UserController extends GetxController {
  // Text controllers
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final alamatController = TextEditingController();
  final kontakController = TextEditingController();
  final penyakitController = TextEditingController();
  final alergiController = TextEditingController();

  // Reactive dropdowns
  var golDarah = ''.obs;
  var jenisKelamin = ''.obs;

  // Reactive location values
  var userLat = 0.0.obs;
  var userLong = 0.0.obs;
  var userProvince = ''.obs;
  var userKota = ''.obs;

  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  var isLoading = false.obs;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🧭 Ambil lokasi user + izin lokasi
  Future<void> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1️⃣ Cek apakah layanan lokasi aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Error', 'Layanan lokasi tidak aktif');
      return;
    }

    // 2️⃣ Minta izin lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar('Error', 'Izin lokasi ditolak');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar('Error', 'Izin lokasi ditolak permanen');
      return;
    }

    // 3️⃣ Ambil lokasi
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    userLat.value = position.latitude;
    userLong.value = position.longitude;

    print('Latitude: ${userLat.value}, Longitude: ${userLong.value}');

    // 4️⃣ Ambil nama provinsi & kota dari koordinat
    await getAddressFromLatLong(userLat.value, userLong.value);
  }

  /// 🌍 Ambil provinsi & kota dari lat/long
  Future<void> getAddressFromLatLong(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        userProvince.value = place.administrativeArea ?? '';
        userKota.value = place.locality ?? place.subAdministrativeArea ?? '';
        print('📍 Kota: ${userKota.value}, Provinsi: ${userProvince.value}');
      } else {
        print('❌ Tidak ada hasil geocoding.');
      }
    } catch (e) {
      print('❌ Gagal mendapatkan alamat: $e');
    }
  }

  Future<void> registerUser() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      // 🔹 Validasi input
      if (emailController.text.isEmpty ||
          usernameController.text.isEmpty ||
          passwordController.text.isEmpty ||
          kontakController.text.isEmpty ||
          golDarah.value.isEmpty ||
          jenisKelamin.value.isEmpty) {
        showAppSnackbar(
          'Error',
          'Harap isi semua data dengan lengkap!',
          isSuccess: false,
        );
        return;
      }

      // 🔹 Pastikan lokasi sudah diambil
      if (userLat.value == 0.0 && userLong.value == 0.0) {
        await getUserLocation();
      }

      // 🔹 Buat akun di Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // 🔹 Ambil token FCM
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // 🔹 Buat objek user model
      final user = UserModel(
        userName: usernameController.text.trim(),
        userEmail: emailController.text.trim(),
        golDarah: golDarah.value,
        penyakitBawaan: penyakitController.text.trim(),
        alergiObat: alergiController.text.trim(),
        userAlamat: alamatController.text.trim(),
        userPhone: kontakController.text.trim(),
        userProvince: userProvince.value,
        userKota: userKota.value,
        userSex: jenisKelamin.value,
        userFCM: fcmToken ?? '',
        userLocation: GeoPoint(userLat.value, userLong.value),
        createdAt: Timestamp.now(),
        lastUpdated: Timestamp.now(),
      );

      // 🔹 Simpan ke Firestore pakai UID
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(user.toMap());

      // 🔹 Notifikasi sukses
      showAppSnackbar('Data telah disimpan', 'Selamat Datang', isSuccess: true);

      clearForm();
      Get.off(MainPage());
    } on FirebaseAuthException catch (e) {
      // 🔹 Tangani error Firebase Auth
      switch (e.code) {
        case 'weak-password':
          showAppSnackbar('Error', 'Password terlalu lemah', isSuccess: false);
          break;
        case 'email-already-in-use':
          showAppSnackbar('Error', 'Email sudah digunakan', isSuccess: false);
          break;
        case 'invalid-email':
          showAppSnackbar(
            'Error',
            'Format email tidak valid',
            isSuccess: false,
          );
          break;
        default:
          showAppSnackbar(
            'Error',
            'Terjadi kesalahan: ${e.message}',
            isSuccess: false,
          );
      }
    } catch (e) {
      // 🔹 Tangani error umum
      showAppSnackbar(
        'Error',
        'Periksa koneksi internet Anda',
        isSuccess: false,
      );
      print('❌ Error: $e');
    } finally {
      // 🔹 Matikan loading
      isLoading.value = false;
    }
  }

  Future<void> loginUser() async {
    isLoading.value = true;
    if (loginEmailController.text.isEmpty ||
        loginPasswordController.text.isEmpty) {
      showAppSnackbar(
        'Error',
        'Email dan password wajib diisi',
        isSuccess: false,
      );
      return;
    }
    if (userLat.value == 0.0 && userLong.value == 0.0) {
      await getUserLocation();
    }

    try {
      isLoading.value = true; // ⏳ Mulai loading

      // 🔹 Login ke Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text.trim(),
      );

      // 🔹 Dapatkan FCM terbaru (optional tapi direkomendasikan)
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // 🔹 Update data di Firestore (terutama lastUpdated dan FCM)

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
            'userFCM': fcmToken ?? '',
            'userLocation': GeoPoint(userLat.value, userLong.value),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

      // 🔹 Notifikasi sukses
      showAppSnackbar('Berhasil', 'Selamat Datang Kembali', isSuccess: true);

      clearForm(); // 🔹 Kosongkan form
      Get.off(MainPage()); // 🔹 Pindah ke halaman utama
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showAppSnackbar('Error', 'Akun tidak ditemukan', isSuccess: false);
      } else if (e.code == 'wrong-password') {
        showAppSnackbar('Error', 'Password salah', isSuccess: false);
      } else {
        showAppSnackbar(
          'Error',
          'Terjadi kesalahan: ${e.code}',
          isSuccess: false,
        );
      }
    } catch (e) {
      showAppSnackbar('Error', 'Gagal login: $e', isSuccess: false);
    } finally {
      isLoading.value = false; // ✅ Akhiri loading
    }
  }

  void clearForm() {
    emailController.clear();
    usernameController.clear();
    passwordController.clear();
    alamatController.clear();
    kontakController.clear();
    penyakitController.clear();
    alergiController.clear();

    loginEmailController.clear();
    loginPasswordController.clear();

    golDarah.value = '';
    jenisKelamin.value = '';
    userLat.value = 0.0;
    userLong.value = 0.0;
    userProvince.value = '';
    userKota.value = '';
  }

  @override
  void onClose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    alamatController.dispose();
    kontakController.dispose();
    penyakitController.dispose();
    alergiController.dispose();
    super.onClose();
  }
}
