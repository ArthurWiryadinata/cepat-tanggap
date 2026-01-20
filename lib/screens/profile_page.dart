import 'package:cepattanggap/controllers/profile_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  ProfilePage(this.username, {super.key});
  final ProfileController profileController = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: Get.mediaQuery.padding.top,
          bottom: 24,
          left: 12,
          right: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi, ${username}!",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE6E6E6), width: 1),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // warna bayangan
                    spreadRadius: 0.1, // sebaran bayangan
                    blurRadius: 6, // tingkat blur
                    offset: const Offset(
                      4,
                      4,
                    ), // posisi bayangan (kanan, bawah)
                  ),
                ],
              ),

              width: double.infinity,

              child: Obx(() {
                final user = profileController.currentUser.value;
                if (user == null) {
                  return Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildInfoRow("Alamat", '-'),
                        buildInfoRow("Kontak", '-'),
                        buildInfoRow("Jenis Kelamin", '-'),
                        buildInfoRow("Golongan Darah", '-'),
                        buildInfoRow("Penyakit Bawaan", '-'),
                        buildInfoRow("Alergi", '-'),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildInfoRow("Alamat", user.userAlamat),
                      buildInfoRow("Kontak", user.userPhone),
                      buildInfoRow("Jenis Kelamin", user.userSex),
                      buildInfoRow("Golongan Darah", user.golDarah),
                      buildInfoRow("Penyakit Bawaan", user.penyakitBawaan),
                      buildInfoRow("Alergi", user.alergiObat),
                    ],
                  ),
                );
              }),
            ),
            Expanded(child: SizedBox()),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0101),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                shape: const RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.8),
              ),
              onPressed: () {
                Get.dialog(
                  Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon Logout
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Title
                          const Text(
                            "KONFIRMASI LOGOUT",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Subtitle
                          const Text(
                            "Apakah kamu yakin ingin logout dari akun ini?",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 16),

                          // Info Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Kamu bisa login kembali kapan saja menggunakan akun yang sama.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              // Logout Button
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () async {
                                    Get.back();
                                    await profileController.logoutUser();
                                  },
                                  child: const Text("Logout"),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Tutup Button
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => Get.back(),
                                  child: const Text(
                                    "Tutup",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Log Out", style: TextStyle(color: Colors.white)),
                  GestureDetector(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130, // pastikan semua label punya lebar sama
          child: Text(label),
        ),
        const Text(": "),
        Expanded(child: Text(value.isNotEmpty ? value : '-')),
      ],
    ),
  );
}
