import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showAppSnackbar(String title, String message, {bool isSuccess = true}) {
  final Color backgroundColor = isSuccess ? Colors.green : Colors.red;
  final IconData icon =
      isSuccess
          ? Icons.check_circle_outline_rounded
          : Icons.error_outline_rounded;

  Get.snackbar(
    title,
    message,
    // 🔧 Custom visual
    backgroundColor: Colors.white,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    borderRadius: 16,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),

    // 🧩 Tambahkan shadow biar lebih menarik
    boxShadows: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],

    // 🕒 Durasi
    duration: const Duration(seconds: 3),

    // 🎨 Custom icon + padding
    icon: Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: Icon(icon, color: backgroundColor, size: 28),
    ),

    // 📏 Title & message text style custom
    titleText: Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
            },
            child: Icon(Icons.close, size: 15),
          ),
        ],
      ),
    ),
    messageText: Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        message,
        style: const TextStyle(color: Colors.black, fontSize: 14),
      ),
    ),

    // 💨 Animasi masuk & keluar
    forwardAnimationCurve: Curves.easeOutBack,
    reverseAnimationCurve: Curves.easeInBack,

    // 🚀 Transisi & dismiss
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
  );
}
