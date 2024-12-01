import 'package:flutter/material.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      height: 100,
      child: Stack(
        children: [
          Positioned(
            left: -25,
            right: -25,
            top: 30,
            child: Container(
              width: 390,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  width: 0.50,
                  color: Colors.black.withOpacity(0.28999999165534973),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, -4),
                    spreadRadius: 0,
                  ),
                ],
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Positioned(
            left: 159,
            top: 5,
            child: Container(
              width: 88,
              height: 57,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, -4),
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 164,
            top: 9,
            child: GestureDetector(
              onTap: () {
                widget.onTap(0);
              },
              onTapDown: (_) {
                setState(() {
                  _hoveredIndex = 0;
                });
              },
              child: Container(
                width: 78,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.currentIndex == 0
                      ? Color(0xFFA4A4A4)
                      : _hoveredIndex == 0
                          ? Color(0xFFA4A4A4)
                          : Color(0xFF0E197E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
          Positioned(
            left: 300,
            top: 40,
            child: GestureDetector(
              onTap: () {
                widget.onTap(1);
              },
              onTapDown: (_) {
                setState(() {
                  _hoveredIndex = 1;
                });
              },
              child: Container(
                width: 29,
                height: 26,
                decoration: BoxDecoration(
                  color: widget.currentIndex == 1
                      ? Color(0xFF0E197E)
                      : _hoveredIndex == 1
                          ? Color(0xFF0E197E)
                          : Color(0xFFA4A4A4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            left: 60,
            top: 40,
            child: GestureDetector(
              onTap: () {
                widget.onTap(2);
              },
              onTapDown: (_) {
                setState(() {
                  _hoveredIndex = 2;
                });
              },
              child: Container(
                width: 35,
                height: 31,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home,
                  color: widget.currentIndex == 2
                      ? Color(0xFF0E197E)
                      : _hoveredIndex == 2
                          ? Color(0xFF0E197E)
                          : Color(0xFFA4A4A4),
                  size: 30,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 176,
            top: 70,
            child: Text(
              'Pengaduan',
              style: TextStyle(
                color: Color(0xFF6E6E6E),
                fontSize: 10,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Positioned(
            left: 58,
            top: 70,
            child: Text(
              'Beranda',
              style: TextStyle(
                color: Color(0xFF6E6E6E),
                fontSize: 10,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Positioned(
            left: 303,
            top: 70,
            child: Text(
              'Profil',
              style: TextStyle(
                color: Color(0xFF6E6E6E),
                fontSize: 10,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
