import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cepattanggap/models/weather_model.dart';

class WeatherController extends GetxController {
  // Observable variables
  var isLoading = true.obs;
  var weatherData = Rxn<WeatherModel>();
  var errorMessage = ''.obs;

  // Open-Meteo API - Gratis, tidak perlu API key
  // API yang lebih reliable dan mudah digunakan
  final String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  void onInit() {
    super.onInit();
    fetchWeatherByLocation();
  }

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
      // Gunakan geocoding API gratis dari Open-Meteo
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
      isLoading.value = true;
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
      isLoading.value = false;
    }
  }

  // Fetch cuaca berdasarkan koordinat
  Future<void> fetchWeatherByCoordinates(
    double lat,
    double lon,
    String cityName,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // API Open-Meteo dengan parameter lengkap
      final url = Uri.parse(
        '$baseUrl?latitude=$lat&longitude=$lon'
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
          isLoading.value = false;
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
          isLoading.value = false;
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
      isLoading.value = false;
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
