import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ssh_aplication/package/UserPage/DasboardPage.dart';
import 'package:ssh_aplication/package/UserPage/LoadPage.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Pastikan ini dipanggil sebelum inisialisasi
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  initializeDateFormatting().then((_) {
    runApp(const MyApp());
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(message.notification!.title.toString());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Stop Sexual Harasment",
      navigatorKey: navigatorKey,
      home: LoadPage(),
      initialRoute: '/', // Rute awal
      routes: {
        '/dashboard': (context) =>
            DasboardPage(), // Rute untuk halaman dashboard
      },
    );
  }
}
