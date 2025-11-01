import 'package:audioplayers/audioplayers.dart';
import 'package:cepattanggap/firebase_options.dart';
import 'package:cepattanggap/screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

const platform = MethodChannel('com.example.cepattanggap/channel');

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📩 Background message: ${message.data}");
}

class FullScreenAlertPage extends StatefulWidget {
  final String title;
  final String message;

  const FullScreenAlertPage({
    required this.title,
    required this.message,
    Key? key,
  }) : super(key: key);

  @override
  State<FullScreenAlertPage> createState() => _FullScreenAlertPageState();
}

class _FullScreenAlertPageState extends State<FullScreenAlertPage> {
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    _player.play(AssetSource('sounds/alarms2.mp3')); // pastikan ada di assets

    Vibration.vibrate(pattern: [0, 800, 500, 800], repeat: 0);
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[700],
      body: GestureDetector(
        onTap: () {
          _player.stop(); // hentikan suara alarm
          Navigator.pop(context); // tutup halaman
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/warning.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 5),
                Text(
                  "Peringatan ${widget.title} !",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final token = await FirebaseMessaging.instance.getToken();
  print("📱 FCM Token: $token");
  await FirebaseMessaging.instance.subscribeToTopic('all_users');
  print("✅ Device subscribed to all_users");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final type = message.data['type'] ?? '';
    if (type == 'emergency') {
      final title = message.notification?.title ?? '🚨 Emergency!';
      final msg = message.notification?.body ?? 'Segera lakukan tindakan!';

      // 🚨 Munculkan layar merah langsung di Flutter
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => FullScreenAlertPage(title: title, message: msg),
        ),
      );
    }
  });

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // 🔹 Saat app foreground
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    //   print('🔥 Foreground message: ${message.data}');
    // });

    // 🔹 Saat user klik notifikasi
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 Notifikasi diklik!');
      // Navigasi ke halaman tertentu
      Get.to(() => LoginPage());
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // ✅ Tambahkan baris ini
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme).apply(
          fontSizeFactor: 0.9, // ⬅️ Kurangi ukuran semua teks 10%
        ),
      ),
      home: LoginPage(),
    );
  }
}
