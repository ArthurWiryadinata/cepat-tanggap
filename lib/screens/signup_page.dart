import 'package:cepattanggap/controllers/user_controller.dart';
import 'package:cepattanggap/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupPage extends StatelessWidget {
  final controller = Get.put(UserController());
  SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(top: Get.mediaQuery.padding.top),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo_bg_gede.png',
                      width: 50,
                      height: 50,
                    ),

                    Image.asset(
                      'assets/images/Cepat Tanggap.png',
                      width: 151,
                      height: 38,
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                        bottomLeft: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                      image: DecorationImage(
                        image: AssetImage('assets/images/background.jpeg'),
                        repeat: ImageRepeat.repeat,
                        opacity: 0.7,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 16,
                        bottom: 16,
                        left: 30,
                        right: 30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sign Up",
                            style: GoogleFonts.bebasNeue(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 0),
                          const Text("Silahkan isi untuk melanjutkan"),
                          const SizedBox(height: 15),
                          CustomTextField(
                            label: "Email*",
                            hint: "Masukkan email kamu",
                            controller: controller.emailController,
                            isNum: false,
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            label: "Username*",
                            hint: "Masukkan nama kamu",
                            controller: controller.usernameController,
                            isNum: false,
                          ),
                          const SizedBox(height: 10),

                          CustomTextField(
                            label: "Password*",
                            hint: "Masukkan password kamu",
                            controller: controller.passwordController,
                            isNum: false,
                          ),
                          const SizedBox(height: 10),

                          CustomTextField(
                            label: "Alamat",
                            hint: "Masukkan alamat kamu",
                            controller: controller.alamatController,
                            isNum: false,
                          ),
                          const SizedBox(height: 10),

                          CustomTextField(
                            label: "Nomor Telepon*",
                            hint: "Masukkan kontak kamu",
                            controller: controller.kontakController,
                            isNum: true,
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Golongan Darah*"),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Obx(
                                        () => DropdownButtonFormField<String>(
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          value:
                                              controller.golDarah.value.isEmpty
                                                  ? null
                                                  : controller.golDarah.value,
                                          hint: const Text("Gol Darah"),
                                          items: const [
                                            DropdownMenuItem(
                                              value: "O",
                                              child: Text("O"),
                                            ),
                                            DropdownMenuItem(
                                              value: "A",
                                              child: Text("A"),
                                            ),
                                            DropdownMenuItem(
                                              value: "B",
                                              child: Text("B"),
                                            ),
                                            DropdownMenuItem(
                                              value: "AB",
                                              child: Text("AB"),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            controller.golDarah.value =
                                                value ?? '';
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Jenis Kelamin*"),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.black12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Obx(
                                        () => DropdownButtonFormField<String>(
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          value:
                                              controller
                                                      .jenisKelamin
                                                      .value
                                                      .isEmpty
                                                  ? null
                                                  : controller
                                                      .jenisKelamin
                                                      .value,
                                          hint: const Text("L/P"),
                                          items: const [
                                            DropdownMenuItem(
                                              value: "Laki-laki",
                                              child: Text("Laki-laki"),
                                            ),
                                            DropdownMenuItem(
                                              value: "Perempuan",
                                              child: Text("Perempuan"),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            controller.jenisKelamin.value =
                                                value ?? '';
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          CustomTextField(
                            label: "Penyakit bawaan",
                            hint: "Masukkan penyakit bawaan kamu",
                            controller: controller.penyakitController,
                            isNum: false,
                          ),
                          const SizedBox(height: 10),

                          CustomTextField(
                            label: "Alergi",
                            hint: "Masukkan alergi kamu",
                            controller: controller.alergiController,
                            isNum: false,
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: Column(
                              children: [
                                Obx(() {
                                  return Container(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          controller.isLoading.value
                                              ? null // disable button saat loading
                                              : () => controller.registerUser(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 32,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child:
                                          controller.isLoading.value
                                              ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : const Text(
                                                'Sign Up',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  );
                                }),
                                SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Sudah memiliki account? "),
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(LoginPage());
                                      },
                                      child: const Text(
                                        "Log In ",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isNum;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    required this.isNum,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
            ),
          ),
        ),
      ],
    );
  }
}
