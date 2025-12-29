import 'package:cepattanggap/controllers/nav_bar_controller.dart';
import 'package:cepattanggap/widgets/nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});
  final NavBarController navController = Get.put(NavBarController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: navController.pages[navController.selectedIndex.value],
        bottomNavigationBar: NavBar(
          currentIndex: navController.selectedIndex.value,
          onTap: (index) {
            navController.selectedIndex.value = index;
          },
        ),
      ),
    );
  }
}
