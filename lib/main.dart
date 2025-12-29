import 'package:cepattanggap/firebase_options.dart';
import 'package:cepattanggap/screens/alert_page.dart';
import 'package:cepattanggap/screens/login_page.dart';
import 'package:cepattanggap/screens/main_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cepattanggap/controllers/iot_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

const platform = MethodChannel('com.example.cepattanggap/channel');

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📩 Background message: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // final token = await FirebaseMessaging.instance.getToken();
  // print("📱 FCM Token: $token");
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
          builder: (_) => FullScreenAlertPage(title: title, message: msg), //
        ),
      );
    }
  });
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ TAMBAHAN: Binding untuk inisialisasi services
class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Inisialisasi FirebaseService sebagai permanent service
    Get.put(FirebaseService(), permanent: true);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

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
      navigatorKey: navigatorKey,
      initialBinding:
          AppBinding(), // ✅ TAMBAHKAN INI untuk inisialisasi FirebaseService
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        textTheme: GoogleFonts.poppinsTextTheme(
          baseTextTheme,
        ).apply(fontSizeFactor: 0.9),
      ),
      home:
          FirebaseAuth.instance.currentUser == null ? LoginPage() : MainPage(),
    );
  }
}
