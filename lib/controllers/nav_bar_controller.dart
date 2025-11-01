import 'package:cepattanggap/screens/home_page.dart';
import 'package:cepattanggap/screens/map_page.dart';
import 'package:cepattanggap/screens/panduan_page.dart';
import 'package:cepattanggap/screens/profile_page.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NavBarController extends GetxController {
  var selectedIndex = 0.obs;
  var username = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentUsername();
  }

  Future<void> fetchCurrentUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        username.value = doc['userName'] ?? '';
      }
    } catch (e) {
      print("❌ Error fetch username: $e");
    }
  }

  // 🔹 gunakan getter agar reactive
  List<Widget> get pages => [
    Obx(() => HomePage(username.value)),
    MapPage(),
    PanduanPage(),
    Obx(() => ProfilePage(username.value)),
  ];
}
