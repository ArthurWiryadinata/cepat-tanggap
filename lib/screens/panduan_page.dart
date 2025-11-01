import 'package:cepattanggap/controllers/panduan_evac_controller.dart';
import 'package:cepattanggap/screens/panduan_evac.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PanduanPage extends StatelessWidget {
  PanduanPage({super.key});

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
            const Text(
              "PANDUAN KESELAMATAN",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DisasterCard(title: "Gempa", imagePath: 'assets/images/gempa.png'),
            const SizedBox(height: 5),
            DisasterCard(
              title: "Banjir",
              imagePath: 'assets/images/banjir.png',
            ),
            const SizedBox(height: 5),
            DisasterCard(
              title: "Kebakaran",
              imagePath: 'assets/images/api.png',
            ),
          ],
        ),
      ),
    );
  }
}

class DisasterCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback? onTap;

  DisasterCard({
    Key? key,
    required this.title,
    required this.imagePath,
    this.onTap,
  }) : super(key: key);
  final PanduanEvacController panduanEvacController = Get.put(
    PanduanEvacController(),
  );
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () async {
          final panduan = await panduanEvacController.fetchPanduan(title);

          Get.to(() => PanduanEvac(title: title, panduan: panduan));
        },

        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(title)),
              const Icon(Icons.chevron_right_rounded, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
