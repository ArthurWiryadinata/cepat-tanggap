import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFD9D9D9),
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      // selectedItemColor: Color(0xFFFF0101),
      // unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: [
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/images/home.png',
            width: 28,
            height: 28,
            color: currentIndex == 0 ? Color(0xFFFF0101) : Colors.black,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/images/map.png',
            width: 28,
            height: 28,
            color: currentIndex == 1 ? Color(0xFFFF0101) : Colors.black,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/images/guide.png',
            width: 28,
            height: 28,
            color: currentIndex == 2 ? Color(0xFFFF0101) : Colors.black,
          ),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Image.asset(
            'assets/images/profil.png',
            width: 28,
            height: 28,
            color: currentIndex == 3 ? Color(0xFFFF0101) : Colors.black,
          ),
          label: '',
        ),
      ],
    );
  }
}
