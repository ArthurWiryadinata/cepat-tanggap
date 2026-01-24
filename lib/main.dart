import 'package:cepattanggap/firebase_options.dart';
import 'package:cepattanggap/screens/login_page.dart';
import 'package:cepattanggap/screens/main_page.dart';
import 'package:cepattanggap/controllers/Notification_Service.dart';
import 'package:cepattanggap/controllers/location_controller.dart';
import 'package:cepattanggap/controllers/sos_controller.dart';
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
  print("📩 Background message received: ${message.data}");

  // Background handler - Native notification akan di-handle oleh Android
  // Notification akan muncul otomatis via MyFirebaseMessagingService.kt
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Subscribe to topic
  await FirebaseMessaging.instance.subscribeToTopic('all_users');
  print("✅ Device subscribed to all_users topic");

  // ✅ FOREGROUND MESSAGE HANDLER
  // Ketika app sedang aktif/dibuka, handle notifikasi di sini
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('📨 Foreground message received');
    print('   Type: ${message.data['type']}');
    print('   Title: ${message.data['title']}');

    final type = message.data['type'] ?? '';

    if (type == 'emergency') {
      final title = message.data['title'] ?? 'BENCANA TERDETEKSI!';
      final msg = message.data['message'] ?? 'Segera lakukan tindakan!';

      print('Emergency alert - Triggering alarm and dialog');

      // ✅ 1. Trigger alarm SOS
      try {
        final sosController = Get.find<SosController>();
        if (!sosController.isActive.value) {
          sosController.playAlarm();
          print('   ✅ Alarm activated');
        }
      } catch (e) {
        print('   ⚠️ SosController not found: $e');
      }

      // ✅ 2. Show dialog (with delay untuk ensure context ready)
      Future.delayed(Duration(milliseconds: 500), () {
        Get.dialog(
          Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Warning Triangle dengan background merah
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF0000),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons
                            .warning_rounded, // Icon segitiga dengan tanda seru
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Title
                  Text(
                    'BENCANA\nTERDETEKSI!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF0000),
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Bencana terdeteksi di sekitar Anda!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Info box - Alarm telah diaktifkan
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Alarm SOS telah diaktifkan secara otomatis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Instruksi
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Untuk mematikan alarm:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  SizedBox(height: 8),

                  // List instruksi
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Tekan tombol "Matikan Alarm" di bawah',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '2. Atau ketuk 2x tombol SOS merah',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Matikan Alarm Button (Kiri)
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            try {
                              final sosController = Get.find<SosController>();
                              sosController.stopAlarm();
                              print('   ✅ Alarm stopped by user');
                            } catch (e) {
                              print('   ⚠️ Error stopping alarm: $e');
                            }
                            Get.back();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Matikan Alarm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF0000),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      // Tutup Button (Kanan)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFD9D9D9),
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Tutup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: false,
        );
      });

      print('   ✅ Dialog shown');
    }
  });

  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ✅ App Binding - Initialize all services in order
class AppBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 Initializing app services...');

    // 1. Firebase Service (IoT data)
    Get.put(FirebaseService(), permanent: true);
    print('   ✅ FirebaseService initialized');

    // 2. Location Controller (GPS tracking)
    Get.put(LocationController(), permanent: true);
    print('   ✅ LocationController initialized');

    // 3. SOS Controller (Alarm)
    Get.put(SosController(), permanent: true);
    print('   ✅ SosController initialized');

    // 4. Alert Service (Monitor & send push notifications)
    Get.put(AlertService(), permanent: true);
    print('   ✅ AlertService initialized');

    print('✅ All services initialized successfully');
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

    // ✅ Handle notification tap (app opened from terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print('📱 App opened from notification (terminated)');
        _handleNotificationTap(message);
      }
    });

    // ✅ Handle notification tap (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from notification (background)');
      _handleNotificationTap(message);
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] ?? '';

    if (type == 'emergency') {
      print('🚨 Emergency notification tapped, navigating to home...');

      // Navigate to MainPage setelah login check
      Future.delayed(Duration(milliseconds: 1000), () {
        if (FirebaseAuth.instance.currentUser != null) {
          Get.to(() => MainPage());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialBinding: AppBinding(), // ✅ Initialize all services
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
