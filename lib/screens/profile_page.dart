
import 'package:cepattanggap/controllers/profile_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  ProfilePage(this.username, {super.key});
  final ProfileController profileController = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: Get.mediaQuery.padding.top + 5,
          bottom: 24,
          left: 12,
          right: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hi, ${username}!"),
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
              onPressed: () async {
                await profileController.logoutUser();
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
