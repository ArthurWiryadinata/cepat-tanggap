import 'package:cepattanggap/controllers/panduan_evac_controller.dart';
import 'package:cepattanggap/models/panduan_item_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PanduanEvac extends StatelessWidget {
  final String title;
  final PanduanBencana panduan; // 🔹 ubah nama biar jelas

  PanduanEvac({super.key, required this.title, required this.panduan});

  final PanduanEvacController panduanEvacController = Get.put(
    PanduanEvacController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: Get.mediaQuery.padding.top + 5,
          bottom: Get.mediaQuery.padding.bottom,
          left: 12,
          right: 12,
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: Get.back,
                  child: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "PANDUAN KESELAMATAN ${title.toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // ⬇️ Sekarang langsung tampilkan panduan, tanpa FutureBuilder
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📌 Panduan Dalam Ruangan
                    _buildPanduanCard(
                      "Di dalam ruangan,",
                      "assets/images/dalamruangan.png",
                      panduan.panduanDalam,
                    ),
                    const SizedBox(height: 15),
                    // 📌 Panduan Luar Ruangan
                    _buildPanduanCard(
                      "Di luar ruangan,",
                      "assets/images/luarruangan.png",
                      panduan.panduanLuar,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Widget helper untuk bikin card panduan
  Widget _buildPanduanCard(
    String title,
    String imagePath,
    List<PanduanItem> panduanList,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6E6E6), width: 1),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 0.1,
            blurRadius: 6,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  imagePath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        panduanList.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "• ",
                                  style: TextStyle(fontSize: 16, height: 1.5),
                                ),
                                Expanded(
                                  child: Text(
                                    item.teks,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
