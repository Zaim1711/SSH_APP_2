import 'package:flutter/material.dart';

class MyGoogleBtn extends StatelessWidget {
  final Function()? onTap;
  const MyGoogleBtn({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15.0),
        margin: const EdgeInsets.symmetric(horizontal: 120),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Shadow color
              spreadRadius: 2, // How much the shadow spreads
              blurRadius: 5, // How blurry the shadow is
              offset:
                  Offset(0, 3), // Offset in (x,y) to control shadow position
            ),
          ],
        ),
        child: Image.asset('lib/image/logo-google.png'),
        width: 50,
        height: 50, // Menggunakan 'child' untuk menampilkan gambar
        // atau bisa juga menggunakan:
        // child: ImageIcon(AssetImage('assets/logo_google.png')),
      ),
    );
  }
}
