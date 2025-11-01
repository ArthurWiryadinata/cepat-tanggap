import 'package:cepattanggap/controllers/nav_bar_controller.dart';
import 'package:cepattanggap/models/user_model.dart';
import 'package:cepattanggap/screens/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class ProfileController extends GetxController {
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  /// Loading state

  @override
  void onInit() {
    super.onInit();
    fetchCurrentUser(); // 🔹 Ambil data user saat controller diinisialisasi
  }

  Future<void> fetchCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        currentUser.value = UserModel.fromDocument(doc);
      }
    } catch (e) {
      print("❌ Error fetch user: $e");
    }
  }

  Future<void> logoutUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update lastUpdated sebelum logout
        await _firestore.collection('users').doc(user.uid).update({
          'lastUpdated': Timestamp.now(),
        });
      }

      // Logout dari Firebase
      await _auth.signOut();

      // Hapus controller agar state bersih
      Get.delete<ProfileController>();
      Get.delete<NavBarController>();

      Get.offAll(() => LoginPage());
    } catch (e) {
      print("❌ Gagal logout: $e");
    }
  }
}
