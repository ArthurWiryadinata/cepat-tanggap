import 'package:cepattanggap/controllers/user_controller.dart';

import 'package:cepattanggap/screens/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final controller = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_bg_gede.png',
                    width: 100, // perbesar ukuran
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/images/Cepat Tanggap.png',
                    width: 140,
                    height: 30,
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/background.jpeg'),
                repeat: ImageRepeat.repeat,
                opacity: 0.7,
              ),
              border: Border.all(width: 1, color: Colors.grey.withOpacity(0.5)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(50),
                topRight: Radius.circular(50),
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  bottom: Get.mediaQuery.padding.bottom,
                  left: 40,
                  right: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LOG IN",
                      style: GoogleFonts.bebasNeue(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 0),
                    const Text("Please fill out to continue"),
                    const SizedBox(height: 15),
                    const Text("Email"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: controller.loginEmailController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              "Masukkan email kamu", // 👈 ini hint text-nya
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text("Password"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: controller.loginPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              "Masukkan password kamu", // 👈 ini hint text-nya
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    Center(
                      child: Obx(
                        () => Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              elevation: 0,
                            ),
                            onPressed:
                                controller.isLoading.value
                                    ? null // disable tombol saat loading
                                    : () {
                                      controller.loginUser();
                                    },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child:
                                  controller.isLoading.value
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        "Log In",
                                        style: TextStyle(color: Colors.white),
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Doesn’t have an account yet? "),
                        GestureDetector(
                          onTap: () {
                            Get.to(SignupPage());
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
