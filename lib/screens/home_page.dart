import 'package:cepattanggap/controllers/information_controller.dart';
import 'package:cepattanggap/controllers/panduan_evac_controller.dart';
import 'package:cepattanggap/controllers/sos_controller.dart';
import 'package:cepattanggap/controllers/weather_controller.dart';
import 'package:cepattanggap/controllers/iot_controller.dart';
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
  final SosController sosController = Get.put(SosController());
  final WeatherController weatherController = Get.put(WeatherController());

  late final FirebaseService _firebaseService;

  // ✅ Track alarm state
  bool hasAutoTriggeredAlarm = false;
  bool hasShownDialog = false; // ✅ Prevent multiple dialogs

  @override
  void initState() {
    super.initState();

    try {
      _firebaseService = Get.find<FirebaseService>();
    } catch (e) {
      _firebaseService = Get.put(FirebaseService(), permanent: true);
    }

    // ✅ Listen untuk IoT devices changes dengan delay untuk menghindari trigger berlebihan
    ever(_firebaseService.iotDevices, (devices) {
      // Delay 500ms untuk debouncing
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _checkForDisasterAndTriggerAlarm(devices);
        }
      });
    });
  }

  void _checkForDisasterAndTriggerAlarm(List<dynamic> devices) {
    // ✅ Get user location - gunakan default jika belum ada
    double userLat = -6.2088;
    double userLng = 106.8456;

    // TODO: Dapatkan lokasi real-time user dari GPS
    // Untuk sementara gunakan default Jakarta

    // ✅ Cek disaster dalam radius 5km
    final devicesInRadius = _firebaseService.getDevicesInRadius(
      userLat,
      userLng,
      5.0,
    );

    final hasDisaster = devicesInRadius.any((d) => d.disasterType != null);

    print(
      '🔍 Checking disaster: hasDisaster=$hasDisaster, alarmActive=${sosController.isActive.value}, autoTriggered=$hasAutoTriggeredAlarm',
    );

    // ✅ LOGIC PERBAIKAN ALARM
    if (hasDisaster) {
      // Ada bencana terdeteksi
      if (!sosController.isActive.value && !hasAutoTriggeredAlarm) {
        // Alarm belum aktif dan belum pernah di-trigger -> AKTIFKAN ALARM
        print('🚨 TRIGGERING ALARM - Disaster detected!');
        sosController.playAlarm();
        hasAutoTriggeredAlarm = true;

        // Show dialog jika belum pernah ditampilkan
        if (!hasShownDialog) {
          hasShownDialog = true;
          _showDisasterAlertDialog();
        }
      }
    } else {
      // Tidak ada bencana
      if (sosController.isActive.value && hasAutoTriggeredAlarm) {
        // Alarm sedang aktif karena auto-trigger -> MATIKAN ALARM
        print('✅ STOPPING ALARM - No disaster detected');
        sosController.stopAlarm();
        hasAutoTriggeredAlarm = false;
        hasShownDialog = false;
      }
    }
  }

  void _showDisasterAlertDialog() {
    if (!mounted) return;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'BENCANA TERDETEKSI!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bencana terdeteksi di sekitar Anda!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Alarm SOS telah diaktifkan secara otomatis.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Text(
              'Untuk mematikan alarm:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Tekan tombol "Matikan Alarm" di bawah'),
            Text('• Atau ketuk 2x tombol SOS merah'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              sosController.stopAlarm();
              hasAutoTriggeredAlarm = false;
              hasShownDialog = false;
              Get.back();
            },
            child: Text(
              'Matikan Alarm',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              hasShownDialog = false;
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
            child: Text('Tutup'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

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
                          // Manual trigger - bukan auto
                          hasAutoTriggeredAlarm = false;
                        }
                      },
                      onDoubleTap: () {
                        sosController.stopAlarm();
                        hasAutoTriggeredAlarm = false;
                        hasShownDialog = false;
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
                      () => Column(
                        children: [
                          Text(
                            sosController.isActive.value
                                ? "Ketuk 2 kali untuk mematikan alarm"
                                : "Tekan untuk menghidupkan alarm SOS",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (sosController.isActive.value) ...[
                            SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                sosController.stopAlarm();
                                hasAutoTriggeredAlarm = false;
                                hasShownDialog = false;
                              },
                              icon: Icon(Icons.stop),
                              label: Text('Matikan Alarm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
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
                    // ✅ LOKASI TERDAMPAK - WITH DISASTER DETECTION CALLBACK
                    DisasterMapWidget(
                      onDisasterDetected: (hasDisaster) {
                        print(
                          '📍 DisasterMapWidget callback: hasDisaster=$hasDisaster',
                        );

                        if (hasDisaster &&
                            !sosController.isActive.value &&
                            !hasAutoTriggeredAlarm) {
                          print('🚨 Callback TRIGGERING ALARM');
                          sosController.playAlarm();
                          hasAutoTriggeredAlarm = true;

                          if (!hasShownDialog) {
                            hasShownDialog = true;
                            _showDisasterAlertDialog();
                          }
                        } else if (!hasDisaster &&
                            sosController.isActive.value &&
                            hasAutoTriggeredAlarm) {
                          print('✅ Callback STOPPING ALARM');
                          sosController.stopAlarm();
                          hasAutoTriggeredAlarm = false;
                          hasShownDialog = false;
                        }
                      },
                    ),

                    const SizedBox(height: 15),

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

  // Weather Card Methods (same as before)
  Widget _buildWeatherCard(WeatherModel weather) {
    final currentForecast = weather.currentForecast;
    if (currentForecast == null) {
      return _buildWeatherErrorCard('Data perkiraan tidak tersedia');
    }

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
                  onPressed: () => weatherController.refreshWeather(),
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
                _buildWeatherDetail(
                  Icons.schedule,
                  'Waktu',
                  currentForecast.getFormattedTime(),
                ),
              ],
            ),

            if (weather.forecasts.length > 1) ...[
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Perkiraan Selanjutnya',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      weather.forecasts.length > 4
                          ? 4
                          : weather.forecasts.length - 1,
                  itemBuilder: (context, index) {
                    final forecast = weather.forecasts[index + 1];
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

  Widget _buildForecastItem(WeatherForecast forecast) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            forecast.getFormattedTime(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Image.asset(
            forecast.getLocalWeatherImage(),
            width: 30,
            height: 30,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.cloud, size: 30);
            },
          ),
          const SizedBox(height: 4),
          Text(
            '${forecast.temperature}°',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
            Text('Mengambil perkiraan cuaca'),
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
              onPressed: () => weatherController.refreshWeather(),
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
