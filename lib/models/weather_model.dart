class WeatherModel {
  final String location;
  final String provinsi;
  final List<WeatherForecast> forecasts;

  WeatherModel({
    required this.location,
    required this.provinsi,
    required this.forecasts,
  });

  // Get current forecast (first item)
  WeatherForecast? get currentForecast =>
      forecasts.isNotEmpty ? forecasts[0] : null;
}

class WeatherForecast {
  final String datetime;
  final String weatherCode;
  final String weatherDesc;
  final String temperature;
  final String tempUnit;
  final String humidity;
  final String? windSpeed; // TAMBAHAN BARU - optional untuk kecepatan angin

  WeatherForecast({
    required this.datetime,
    required this.weatherCode,
    required this.weatherDesc,
    required this.temperature,
    required this.tempUnit,
    required this.humidity,
    this.windSpeed, // TAMBAHAN BARU
  });

  // Method untuk mendapatkan path gambar lokal berdasarkan kode cuaca
  // Menggunakan WMO Weather interpretation codes (0-99)
  String getLocalWeatherImage() {
    final code = int.tryParse(weatherCode) ?? 0;

    // WMO Weather interpretation codes
    // 0: Cerah
    if (code == 0) {
      return 'assets/images/cerah.png';
    }
    // 1-3: Berawan
    else if (code >= 1 && code <= 3) {
      return 'assets/images/berawan.png';
    }
    // 45-48: Kabut
    else if (code >= 45 && code <= 48) {
      return 'assets/images/berawan.png';
    }
    // 51-57: Gerimis
    else if (code >= 51 && code <= 57) {
      return 'assets/images/hujan.png';
    }
    // 61-67: Hujan
    else if (code >= 61 && code <= 67) {
      return 'assets/images/hujan.png';
    }
    // 71-77: Salju
    else if (code >= 71 && code <= 77) {
      return 'assets/images/salju.png';
    }
    // 80-86: Hujan Lebat
    else if (code >= 80 && code <= 86) {
      return 'assets/images/hujan.png';
    }
    // 95-99: Petir
    else if (code >= 95 && code <= 99) {
      return 'assets/images/petir.png';
    } else {
      return 'assets/images/berawan.png';
    }
  }

  // Get simplified description
  String getSimplifiedDescription() {
    return weatherDesc;
  }

  // Format datetime ke format yang lebih readable
  String getFormattedTime() {
    try {
      final dt = DateTime.parse(datetime);
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return datetime;
    }
  }

  String getFormattedDate() {
    try {
      final dt = DateTime.parse(datetime);
      final days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return '${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month - 1]}';
    } catch (e) {
      return datetime;
    }
  }

  // Check if forecast is for today
  bool isToday() {
    try {
      final dt = DateTime.parse(datetime);
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (e) {
      return false;
    }
  }
}
