import 'package:cepattanggap/controllers/information_controller.dart';
import 'package:cepattanggap/controllers/panduan_evac_controller.dart';
import 'package:cepattanggap/controllers/sos_controller.dart';
import 'package:cepattanggap/models/weather_model.dart';
import 'package:cepattanggap/screens/disaster_map.dart';
import 'package:cepattanggap/screens/panduan_evac.dart';
import 'package:cepattanggap/widgets/snack_bar_custom.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage(this.username, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final InformationController informationController = Get.put(
    InformationController(),
    permanent: true,
  );
  final SosController sosController = Get.find<SosController>();

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
              "Hi, ${widget.username}!",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            // SOS BUTTON CONTAINER
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Butuh Bantuan Darurat?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        if (!sosController.isActive.value) {
                          sosController.playAlarm();
                        }
                      },
                      onDoubleTap: () {
                        sosController.stopAlarm();
                      },
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0101),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 5,
                              offset: const Offset(0, 5),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // EXPANDED + SINGLECHILDSCROLLVIEW
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // PANDUAN KESELAMATAN
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Panduan Keselamatan",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: const [
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

                    const SizedBox(height: 15),

                    // LOKASI TERDAMPAK - Always visible
                    DisasterMapWidget(),

                    const SizedBox(height: 15),

                    // CUACA HARI INI
                    Obx(() {
                      if (informationController.isWeatherLoading.value) {
                        return _buildWeatherLoadingCard();
                      }

                      if (informationController.errorMessage.value.isNotEmpty) {
                        return _buildWeatherErrorCard(
                          informationController.errorMessage.value,
                        );
                      }

                      if (informationController.weatherData.value == null) {
                        return _buildWeatherErrorCard(
                          'Data cuaca tidak tersedia',
                        );
                      }

                      return _buildWeatherCard(
                        informationController.weatherData.value!,
                      );
                    }),

                    const SizedBox(height: 15),

                    // BERITA BENCANA TERKINI
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

  Widget _buildWeatherCard(WeatherModel weather) {
    final currentForecast = weather.currentForecast;
    if (currentForecast == null) {
      return _buildWeatherErrorCard('Data perkiraan tidak tersedia');
    }

    // Ambil 4 forecast berikutnya (tidak termasuk forecast sekarang)
    final nextForecasts = weather.forecasts.skip(1).take(4).toList();

    return Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Perkiraan Cuaca",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentForecast.getFormattedDate(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => informationController.refreshWeather(),
                  tooltip: 'Refresh cuaca',
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    weather.location,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text(
                        "${currentForecast.temperature}°",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentForecast.getFormattedTime(),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Image.asset(
                        currentForecast.getLocalWeatherImage(),
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.cloud, size: 80);
                        },
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currentForecast.getSimplifiedDescription(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherDetail(
                  Icons.water_drop,
                  'Kelembaban',
                  '${currentForecast.humidity}%',
                ),
                if (currentForecast.windSpeed != null)
                  _buildWeatherDetail(
                    Icons.air,
                    'Angin',
                    '${currentForecast.windSpeed} m/s',
                  )
                else
                  _buildWeatherDetail(
                    Icons.schedule,
                    'Waktu',
                    currentForecast.getFormattedTime(),
                  ),
              ],
            ),

            // PERKIRAAN SELANJUTNYA
            if (nextForecasts.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "Perkiraan Selanjutnya",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: nextForecasts.length,
                  itemBuilder: (context, index) {
                    final forecast = nextForecasts[index];
                    return _buildForecastItem(forecast);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForecastItem(WeatherForecast forecast) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            forecast.getFormattedTime(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Image.asset(
            forecast.getLocalWeatherImage(),
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.cloud, size: 40);
            },
          ),
          const SizedBox(height: 8),
          Text(
            "${forecast.temperature}°",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildWeatherLoadingCard() {
    return Container(
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
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Perkiraan Cuaca",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Mengambil perkiraan cuaca dari API...'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherErrorCard(String errorMsg) {
    return Container(
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
          children: [
            const Text(
              "Perkiraan Cuaca",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 10),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => informationController.refreshWeather(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
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
        final panduan = await panduanEvacController.fetchPanduan(label);

        if (panduan.panduanDalam.isEmpty && panduan.panduanLuar.isEmpty) {
          showAppSnackbar(
            'Data belum tersedia',
            'Data keselamatan belum tersedia',
            isSuccess: false,
          );
          return;
        }

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
