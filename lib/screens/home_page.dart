import 'package:cepattanggap/controllers/information_controller.dart';
import 'package:cepattanggap/controllers/panduan_evac_controller.dart';
import 'package:cepattanggap/controllers/sos_controller.dart';
import 'package:cepattanggap/screens/panduan_evac.dart';
import 'package:cepattanggap/widgets/snack_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  final String username;
  HomePage(this.username, {super.key});
  final InformationController informationController = Get.put(
    InformationController(),
    permanent: true,
  );
  final SosController sosController = Get.put(SosController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: Get.mediaQuery.padding.top,
          bottom: 5,
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
            SizedBox(height: 5),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey, width: 0.2),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Butuh Bantuan Darurat?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        sosController.playAlarm();
                      },
                      onDoubleTap: () {
                        sosController.stopAlarm(); // hentikan alarm
                      },
                      child: Container(
                        width: 150, // ukuran lebar lingkaran
                        height: 150, // ukuran tinggi lingkaran
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0101), // warna merah
                          shape: BoxShape.circle, // bentuk lingkaran
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 5,
                              offset: Offset(
                                0,
                                5,
                              ), // (x, y) → x = horizontal, y = vertical
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/alarm.png',
                            width: 127,
                            height: 92,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => Text(
                        sosController.isActive.value
                            ? "Ketuk 2 kali untuk mematikan alarm"
                            : "Tekan untuk menghidupkan alarm SOS",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey, width: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.2,
                            ), // warna bayangan
                            spreadRadius: 0.1, // sebaran bayangan
                            blurRadius: 6, // tingkat blur
                            offset: const Offset(
                              4,
                              4,
                            ), // posisi bayangan (kanan, bawah)
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Lokasi Terdampak",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Peta Lokasi Evakuasi"),
                            Container(
                              width: double.infinity,
                              height: 20,
                              color: Colors.grey,
                            ),
                            Container(
                              padding: const EdgeInsets.only(
                                right: 8,
                                left: 4,
                                top: 4,
                                bottom: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.dangerous,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Darurat",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              children: [
                                Icon(Icons.location_pin),
                                Text("Palmerah, BINUS KMG"),
                              ],
                            ),
                            Container(
                              width: double.infinity,
                              height: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey, width: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.2,
                            ), // warna bayangan
                            spreadRadius: 0.1, // sebaran bayangan
                            blurRadius: 6, // tingkat blur
                            offset: const Offset(
                              4,
                              4,
                            ), // posisi bayangan (kanan, bawah)
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Panduan Keselamatan",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DisasterCard(
                                    imagePath: 'assets/images/gempa.png',
                                    label: 'Gempa',
                                  ),
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  child: DisasterCard(
                                    imagePath: 'assets/images/banjir.png',
                                    label: 'Banjir',
                                  ),
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  child: DisasterCard(
                                    imagePath: 'assets/images/api.png',
                                    label: 'Kebakaran',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey, width: 0.2),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Cuaca hari ini",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text(
                                      "24",
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      Image.asset('assets/images/berawan.png'),
                                      const SizedBox(height: 5),
                                      const Text("Berawan"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey, width: 0.2),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              "Berita bencana terkini,",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${DateFormat("dd MMMM yyyy", "id_ID").format(DateTime.now())}",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 15),
                            FutureBuilder<List<Map<String, String>>>(
                              future: informationController.fetchDisasterNews(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                    child: Text('Tidak ada berita'),
                                  );
                                }

                                final newsList = snapshot.data!;
                                return ListView.builder(
                                  padding: EdgeInsets.all(0),
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: newsList.length,
                                  itemBuilder: (context, index) {
                                    final news = newsList[index];
                                    return Card(
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 0.5,
                                        ),
                                      ),
                                      elevation: 4,
                                      shadowColor: Colors.black.withOpacity(
                                        0.2,
                                      ),
                                      child: ListTile(
                                        onTap: () {
                                          final url = news['sourceUrl']!;
                                          launchUrl(
                                            Uri.parse(url),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        },

                                        leading: Icon(Icons.newspaper),
                                        title: Text(
                                          news['title']!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          "Dipublikasi oleh: ${news['source']!}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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
}

class DisasterCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback? onTap;

  const DisasterCard({
    super.key,
    required this.imagePath,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panduanEvacController = Get.put(PanduanEvacController());

    return GestureDetector(
      onTap: () async {
        // ambil data
        final panduan = await panduanEvacController.fetchPanduan(label);

        // cek kosong
        if (panduan.panduanDalam.isEmpty && panduan.panduanLuar.isEmpty) {
          showAppSnackbar(
            'Data belum tersedia',
            'Data keselamatan belum tersedia',
            isSuccess: false,
          );
          return;
        }

        // kalau ada navigasi
        Get.to(() => PanduanEvac(title: label, panduan: panduan));
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 50, height: 50, fit: BoxFit.contain),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
