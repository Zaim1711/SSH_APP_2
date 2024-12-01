import 'package:flutter/material.dart';

class InformationPage extends StatefulWidget {
  @override
  _InformationPageState createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  List<InformationItem> informationList = [
    InformationItem(
      question: 'Apa itu Hak dan Hukum?',
      answer:
          'Hak dan hukum adalah seperangkat aturan dan norma yang mengatur perilaku manusia dalam suatu masyarakat.',
    ),
    InformationItem(
      question: 'Apa itu Hukum Perdata?',
      answer:
          'Hukum perdata adalah bagian dari hukum yang mengatur hubungan antara individu atau badan hukum yang bersifat pribadi.',
    ),
    InformationItem(
      question: 'Apa itu Hukum Pidana?',
      answer:
          'Hukum pidana adalah bagian dari hukum yang mengatur pelanggaran hukum dan menetapkan sanksi atau hukuman terhadap pelaku kejahatan.',
    ),
    InformationItem(
      question: 'Apa saja hak korban kekerasan seksual?',
      answer:
          'Korban kekerasan seksual memiliki hak untuk mendapatkan perlindungan, dukungan, dan akses terhadap keadilan. Mereka berhak mendapatkan informasi tentang proses hukum, layanan medis, dan dukungan psikologis.',
    ),
    InformationItem(
      question: 'Apa saja hak pelaku kekerasan seksual?',
      answer:
          'Pelaku kekerasan seksual memiliki hak untuk mendapatkan peradilan yang adil, hak untuk didampingi oleh penasihat hukum, dan hak untuk tidak diperlakukan secara diskriminatif selama proses hukum.',
    ),
    InformationItem(
      question:
          'Apa yang harus dilakukan jika Anda menjadi korban kekerasan seksual?',
      answer:
          'Jika Anda menjadi korban kekerasan seksual, segera laporkan kepada pihak berwenang atau lembaga yang dapat memberikan bantuan. Anda berhak mendapatkan perlindungan, dukungan medis, dan akses ke layanan konseling.',
    ),
    InformationItem(
      question: 'Bagaimana proses hukum bagi pelaku kekerasan seksual?',
      answer:
          'Pelaku kekerasan seksual akan melalui proses hukum yang sesuai dengan hukum pidana. Mereka berhak untuk membela diri di pengadilan dan mendapatkan penasihat hukum untuk mendampingi mereka.',
    ),
    InformationItem(
      question: 'Apa itu kekerasan seksual?',
      answer:
          'Kekerasan seksual adalah tindakan yang melanggar kebebasan seksual seseorang, termasuk pemaksaan, pelecehan, atau eksploitasi seksual tanpa persetujuan.',
    ),
    InformationItem(
      question: 'Apa yang dimaksud dengan perlindungan hukum bagi korban?',
      answer:
          'Perlindungan hukum bagi korban mencakup langkah-langkah untuk menjaga keamanan dan privasi korban selama proses hukum, termasuk perlindungan identitas dan dukungan psikologis.',
    ),
    InformationItem(
      question: 'Apa yang dimaksud dengan restitusi bagi korban?',
      answer:
          'Restitusi adalah kompensasi yang diberikan kepada korban oleh pelaku sebagai ganti kerugian yang dialami akibat tindak kekerasan seksual, yang dapat mencakup biaya medis dan dukungan psikologis.',
    ),
    InformationItem(
      question: 'Apa itu mediasi dalam kasus kekerasan seksual?',
      answer:
          'Mediasi adalah proses penyelesaian sengketa di mana pihak-pihak yang terlibat bertemu dengan mediator untuk mencapai kesepakatan. Namun, mediasi tidak selalu dianjurkan dalam kasus kekerasan seksual karena kompleksitas dan sensitivitasnya.',
    ),
    InformationItem(
      question:
          'Apa itu Undang-Undang Tindak Pidana Kekerasan Seksual (UU TPKS)?',
      answer:
          'UU TPKS adalah Undang-Undang Nomor 12 Tahun 2022 yang mengatur tentang tindak pidana kekerasan seksual, termasuk perlindungan bagi korban dan sanksi bagi pelaku.',
    ),
    InformationItem(
      question: 'Apa saja ketentuan penting dalam UU TPKS?',
      answer:
          'UU TPKS mencakup definisi kekerasan seksual, perlindungan hukum bagi korban, sanksi bagi pelaku, dan prosedur hukum yang jelas untuk penanganan kasus kekerasan seksual.',
    ),
    InformationItem(
      question: 'Apa itu restitusi dalam konteks kekerasan seksual?',
      answer:
          'Restitusi adalah kompensasi yang diberikan oleh pelaku kepada korban sebagai ganti rugi atas kerugian yang dialami akibat tindak kekerasan seksual.',
    ),
  ];

  int _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Informasi Hak dan Hukum',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF0E197E),
        leading: BackButton(
          color: Colors.white,
        ),
      ),
      body: Container(
        color: Colors.grey[200],
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: ExpansionPanelList(
            elevation: 1,
            expandedHeaderPadding: EdgeInsets.all(0),
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _expandedIndex = isExpanded ? -1 : index;
              });
            },
            children:
                informationList.map<ExpansionPanel>((InformationItem item) {
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
                      padding: EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.question,
                              style: TextStyle(
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
                    item.answer,
                    style: TextStyle(
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
      ),
    );
  }
}

class InformationItem {
  final String question;
  final String answer;

  InformationItem({required this.question, required this.answer});
}
