import 'package:flutter/material.dart';

class SearchInput extends StatelessWidget {
  final Function(String) onSearchChanged;

  const SearchInput({super.key, required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5), // Warna dan opasitas shadow
              spreadRadius: 2, // Menyebar dari pusat shadow
              blurRadius: 5, // Besar efek blur pada shadow
              offset: const Offset(0, 3), // Posisi shadow (x, y)
            ),
          ],
        ),
        child: TextField(
          onChanged: onSearchChanged,
          style: const TextStyle(color: Color(0xFF0D187E)),
          decoration: const InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(
              Icons.search,
              color: Color(0xFF0D187E),
            ), // Icon search di bagian depan TextField
            border: InputBorder.none, // Menghapus border bawaan
            contentPadding:
                EdgeInsets.all(12.0), // Padding konten dalam TextField
          ),
        ),
      ),
    );
  }
}
