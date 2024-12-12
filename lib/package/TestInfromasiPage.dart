import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/model/InformasiHakdanHukum.dart';

class InformationPage extends StatefulWidget {
  @override
  _InformationPageState createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  List<Informasihakdanhukum> informationList = [];
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchInformation();
  }

  Future<void> _fetchInformation() async {
    // Mengambil token dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(
        'accesToken'); // Ganti 'accessToken' dengan kunci yang sesuai

    // Mengirimkan permintaan GET dengan header Authorization
    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8080/informasiHakHukum'), // Ganti dengan URL yang sesuai
      headers: {
        'Authorization':
            'Bearer $accessToken', // Menambahkan Authorization header
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        informationList =
            data.map((item) => Informasihakdanhukum.fromJson(item)).toList();
      });
    } else {
      throw Exception('Failed to load information');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Informasi Hak dan Hukum',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF0E197E),
          leading: const BackButton(
            color: Colors.white,
          ),
        ),
        body: Container(
          color: Colors.grey[200],
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ExpansionPanelList(
              elevation: 1,
              expandedHeaderPadding: const EdgeInsets.all(0),
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  _expandedIndex = isExpanded ? -1 : index;
                });
              },
              children: informationList
                  .map<ExpansionPanel>((Informasihakdanhukum item) {
                return ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedIndex =
                              isExpanded ? -1 : informationList.indexOf(item);
                        });
                      },
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.judul, // Menggunakan judul dari model
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      item.deskripsi, // Menggunakan deskripsi dari model
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  isExpanded: informationList.indexOf(item) == _expandedIndex,
                );
              }).toList(),
            ),
          ),
        ));
  }
}
