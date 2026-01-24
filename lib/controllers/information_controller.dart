import 'package:cepattanggap/models/news_model.dart';
import 'package:cepattanggap/models/weather_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:xml/xml.dart' as xml;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

class InformationController extends GetxController {
  // News variables
  var newsList = <NewsArticle>[].obs;
  var isNewsLoading = false.obs;

  // Weather variables
  var isWeatherLoading = true.obs;
  var weatherData = Rxn<WeatherModel>();
  var errorMessage = ''.obs;

  final String weatherBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  void onInit() {
    super.onInit();
    fetchWeatherByLocation();
  }

  // ==================== NEWS METHODS ====================

  Future<List<Map<String, String>>> fetchDisasterNews() async {
    final rssUrl =
        'https://news.google.com/rss/search?q=disaster+OR+earthquake+OR+flood&hl=en-US&gl=US&ceid=US:en';

    final response = await http.get(
      Uri.parse(rssUrl),
      headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal load RSS');
    }

    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');

    return items.map((node) {
      final rawTitle = node.findElements('title').first.text;
      final title = rawTitle.split(' - ')[0];

      final link = node.findElements('link').first.text;
      final pubDate = node.findElements('pubDate').first.text;

      final sourceElement = node.findElements('source').first;
      final sourceName = sourceElement.text;
      final sourceUrl = sourceElement.getAttribute('url') ?? "";

      return {
        'title': title,
        'link': link,
        'pubDate': pubDate,
        'source': sourceName,
        'sourceUrl': sourceUrl,
      };
    }).toList();
  }

  // ==================== WEATHER METHODS ====================

  // Cek dan minta permission lokasi
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage.value = 'Location services tidak aktif';
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        errorMessage.value = 'Izin lokasi ditolak';
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      errorMessage.value =
          'Izin lokasi ditolak permanen. Aktifkan di pengaturan.';
      return false;
    }

    return true;
  }

  // Dapatkan lokasi user
  Future<Position?> _getCurrentLocation() async {
    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      errorMessage.value = 'Gagal mendapatkan lokasi: $e';
      return null;
    }
  }

  // Dapatkan nama kota dari koordinat menggunakan reverse geocoding
  Future<String> _getCityName(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?latitude=$lat&longitude=$lon&count=1&language=id&format=json',
      );

      final response = await http.get(url).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          return result['name'] ?? 'Unknown';
        }
      }
    } catch (e) {
      print('Geocoding error: $e');
    }

    return 'Lokasi Anda';
  }

  // Fetch perkiraan cuaca berdasarkan lokasi user
  Future<void> fetchWeatherByLocation() async {
    try {
      isWeatherLoading.value = true;
      errorMessage.value = '';

      // Dapatkan lokasi
      final position = await _getCurrentLocation();
      if (position == null) {
        // Jika gagal dapat lokasi, gunakan default Jakarta
        await fetchWeatherByCoordinates(-6.2088, 106.8456, 'Jakarta');
        return;
      }

      // Dapatkan nama kota
      final cityName = await _getCityName(
        position.latitude,
        position.longitude,
      );

      // Fetch data cuaca
      await fetchWeatherByCoordinates(
        position.latitude,
        position.longitude,
        cityName,
      );
    } catch (e) {
      errorMessage.value = 'Error: $e';
      isWeatherLoading.value = false;
    }
  }

  // Fetch cuaca berdasarkan koordinat
  Future<void> fetchWeatherByCoordinates(
    double lat,
    double lon,
    String cityName,
  ) async {
    try {
      isWeatherLoading.value = true;
      errorMessage.value = '';

      // API Open-Meteo dengan parameter lengkap
      final url = Uri.parse(
        '$weatherBaseUrl?latitude=$lat&longitude=$lon'
        '&hourly=temperature_2m,relativehumidity_2m,weathercode,windspeed_10m'
        '&timezone=Asia/Jakarta'
        '&forecast_days=2',
      );

      print('Fetching weather from: $url');

      final response = await http
          .get(url)
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Timeout: Server tidak merespons');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['hourly'] == null) {
          errorMessage.value = 'Data perkiraan cuaca tidak tersedia';
          isWeatherLoading.value = false;
          return;
        }

        // Parse data cuaca
        final hourly = data['hourly'];
        final times = List<String>.from(hourly['time']);
        final temperatures = List<double>.from(
          hourly['temperature_2m'].map((e) => e.toDouble()),
        );
        final humidities = List<int>.from(hourly['relativehumidity_2m']);
        final weatherCodes = List<int>.from(hourly['weathercode']);
        final windSpeeds = List<double>.from(
          hourly['windspeed_10m'].map((e) => e.toDouble()),
        );

        // Buat list forecast (ambil 8 jam ke depan)
        final forecasts = <WeatherForecast>[];
        final now = DateTime.now();

        for (int i = 0; i < times.length && forecasts.length < 8; i++) {
          final forecastTime = DateTime.parse(times[i]);

          // Hanya ambil forecast yang >= waktu sekarang
          if (forecastTime.isAfter(now) || forecastTime.isAtSameMomentAs(now)) {
            forecasts.add(
              WeatherForecast(
                datetime: times[i],
                weatherCode: weatherCodes[i].toString(),
                weatherDesc: _getWeatherDescription(weatherCodes[i]),
                temperature: temperatures[i].round().toString(),
                tempUnit: 'C',
                humidity: humidities[i].toString(),
                windSpeed: windSpeeds[i].toStringAsFixed(1),
              ),
            );
          }
        }

        if (forecasts.isEmpty) {
          errorMessage.value = 'Data perkiraan cuaca tidak tersedia';
          isWeatherLoading.value = false;
          return;
        }

        weatherData.value = WeatherModel(
          location: cityName,
          provinsi: 'Indonesia',
          forecasts: forecasts,
        );

        errorMessage.value = '';
      } else {
        errorMessage.value =
            'Gagal mengambil data cuaca (${response.statusCode})';
      }
    } catch (e) {
      print('Weather fetch error: $e');
      errorMessage.value = 'Error: ${e.toString()}';
    } finally {
      isWeatherLoading.value = false;
    }
  }

  // Convert weather code ke deskripsi
  String _getWeatherDescription(int code) {
    // WMO Weather interpretation codes
    if (code == 0) return 'Cerah';
    if (code >= 1 && code <= 3) return 'Berawan';
    if (code >= 45 && code <= 48) return 'Berkabut';
    if (code >= 51 && code <= 57) return 'Gerimis';
    if (code >= 61 && code <= 65) return 'Hujan';
    if (code >= 66 && code <= 67) return 'Hujan Beku';
    if (code >= 71 && code <= 77) return 'Salju';
    if (code >= 80 && code <= 82) return 'Hujan Lebat';
    if (code >= 85 && code <= 86) return 'Salju Lebat';
    if (code >= 95 && code <= 99) return 'Hujan Petir';
    return 'Berawan';
  }

  // Refresh cuaca
  Future<void> refreshWeather() async {
    await fetchWeatherByLocation();
  }

  // Format suhu
  String getFormattedTemperature() {
    final forecast = weatherData.value?.currentForecast;
    if (forecast == null) return '--';
    return '${forecast.temperature}°${forecast.tempUnit}';
  }
}
