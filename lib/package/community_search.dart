import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ssh_aplication/component/bottom_navigator.dart';
import 'package:ssh_aplication/package/DasboardPage.dart';
import 'package:ssh_aplication/package/TestMultiPage.dart';

import '../component/Search.dart';
import 'ProfilePage.dart';

class Community_Search extends StatefulWidget {
  @override
  _Community_SearchState createState() => _Community_SearchState();
}

class _Community_SearchState extends State<Community_Search> {
  int _currentIndex = 0;
  List<dynamic> ongoingEvents = [];

  @override
  void initState() {
    super.initState();
    _loadOngoingEvents();
  }

  _loadOngoingEvents() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:8080/products'));
    if (response.statusCode == 200) {
      setState(() {
        ongoingEvents = json.decode(response.body);
      });
    } else {
      print('Gagal mengambil data: ${response.statusCode}');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  MultiPageForm()), // Make sure this is the correct navigation logic
        );
      }
      if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DasboardPage()),
        );
      }
      if (index == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
        );
      }
    });
  }

  // Fungsi untuk pemrosesan pencarian
  void _performSearch(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        // Jika teks pencarian kosong, tampilkan semua acara yang sedang berlangsung
        // Anda mungkin perlu memodifikasi logika ini berdasarkan kebutuhan Anda
        _loadOngoingEvents();
      } else {
        // Filter ongoingEvents berdasarkan kueri pencarian
        ongoingEvents = ongoingEvents.where((event) {
          String eventName = event['name'].toLowerCase();
          String eventDescription = event['description'].toLowerCase();
          return eventName.contains(searchText.toLowerCase()) ||
              eventDescription.contains(searchText.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Container(
              width: 450,
              height: 180,
              decoration: ShapeDecoration(
                color: const Color(0xFFF4F4F4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Image(
                            image: AssetImage('lib/image/Logo.png'),
                            width: 100,
                            height: 80,
                          ),
                          SearchInput(onSearchChanged: _performSearch),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: ongoingEvents.length,
                itemBuilder: (context, index) {
                  var event = ongoingEvents[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    width: 342,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 93,
                          top: 42,
                          child: Text(
                            '${event['stock']}',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.47),
                              fontSize: 15,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 93,
                          top: 11,
                          child: SizedBox(
                            width: 249,
                            child: Text(
                              '${event['name']}\n${event['description']}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 7,
                          top: 6,
                          child: Container(
                            width: 71,
                            height: 71,
                            decoration: ShapeDecoration(
                              image: const DecorationImage(
                                image: NetworkImage(
                                    "https://via.placeholder.com/71x71"),
                                fit: BoxFit.cover,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 278,
                          top: 63,
                          child: Text(
                            '${event['prize']}',
                            style: const TextStyle(
                              color: Color(0xFF0E197E),
                              fontSize: 8,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
