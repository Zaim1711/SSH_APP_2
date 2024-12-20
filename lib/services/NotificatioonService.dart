import 'dart:async';
import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/main.dart';
import 'package:ssh_aplication/model/NotificationRequest.dart';
import 'package:ssh_aplication/package/LandingPageChat.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final String baseUrl = 'http://10.0.2.2:8080/api/tokens';
  StreamSubscription? _messageSubscription;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Inisialisasi notifikasi
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onSelectNotification);

    // Membuat saluran notifikasi
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'your_channel_id', // ID saluran
      'Your Channel Name', // Nama saluran
      description: 'Your channel description',
      importance: Importance.high,
    );

    // Buat saluran (akan menimpa jika sudah ada)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Pastikan ini cocok dengan ID saluran Anda
      'Your Channel Name', // Nama saluran
      channelDescription: 'Your channel description', // Deskripsi saluran
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: '@mipmap/ic_launcher', // Gunakan ikon kecil Anda di sini
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      DateTime.now()
          .millisecondsSinceEpoch
          .remainder(100000), // ID unik untuk setiap notifikasi
      title, // Judul notifikasi
      body, // Isi notifikasi
      platformChannelSpecifics,
      payload: 'item x', // Anda dapat menyesuaikan payload ini sesuai kebutuhan
    );
  }

  Future<void> onSelectNotification(NotificationResponse response) async {
    // Ambil BuildContext dari global key atau state management
    final context = navigatorKey
        .currentContext; // Misalkan Anda menggunakan GlobalKey<NavigatorState>

    if (context != null) {
      // Tangani logika ketika notifikasi ditekan
      print('Payload notifikasi: ${response.payload}');

      // Jika Anda ingin membuka UserListChat tanpa menggunakan payload
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              LandingPageChatRooms(), // Ganti ini dengan halaman yang ingin Anda buka
        ),
      );
    } else {
      print('Context tidak tersedia');
    }
  }

  void configureFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Menerima pesan di latar depan: ${message.messageId}");

      // Periksa apakah payload notifikasi ada
      if (message.notification != null) {
        // Tampilkan notifikasi menggunakan judul dan isi notifikasi
        showNotification(
          message.notification!.title ?? 'Tanpa Judul',
          message.notification!.body ?? 'Tanpa Isi',
        );
      }

      // Periksa apakah payload data ada
      if (message.data.isNotEmpty) {
        String senderId = message.data['senderId'] ?? 'Pengirim Tidak Dikenal';
        String messageContent =
            message.data['messageContent'] ?? 'Tanpa Konten';

        // Opsional, tampilkan notifikasi untuk pesan data juga
        showNotification('Pesan Baru dari $senderId', messageContent);
      }
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Menangani pesan latar belakang: ${message.messageId}");

    // Periksa apakah payload notifikasi ada
    if (message.notification != null) {
      // Tampilkan notifikasi saat aplikasi berada di latar belakang
      final service = NotificationService();
      await service.showNotification(
        message.notification!.title ?? 'Tanpa Judul',
        message.notification!.body ?? 'Tanpa Isi',
      );
    } else {
      // Tangani kasus di mana payload notifikasi null
      print('Payload notifikasi latar belakang adalah null');
    }

    // Jika ada data tambahan
    if (message.data.isNotEmpty) {
      String chatRoomId = message.data['roomId'] ?? '';
      String senderId = message.data['senderId'] ?? '';
      String messageContent = message.data['messageContent'] ?? '';

      // Tampilkan notifikasi dengan informasi tambahan
      final service = NotificationService();
      await service.showNotification(
          'Pesan Baru dari $senderId', // Judul notifikasi
          messageContent // Isi notifikasi
          );
    }
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Pengguna memberikan izin');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('Pengguna memberikan izin sementara');
    } else {
      AppSettings.openAppSettings();
      print('Pengguna menolak atau belum memberikan izin');
    }
  }

  Future<void> getDeviceToken() async {
    try {
      // Mendapatkan token perangkat
      String? deviceToken = await messaging.getToken();
      if (deviceToken != null) {
        // Mendapatkan ID pengguna dari token akses
        await decodeTokenAndSendToServer(deviceToken);
      } else {
        print('Token perangkat tidak ditemukan');
      }
    } catch (e) {
      print('Error mendapatkan token perangkat: $e');
    }
  }

  Future<void> decodeTokenAndSendToServer(String deviceToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null) {
      // Mendekode token JWT
      Map<String, dynamic> payload = JwtDecoder.decode(accessToken);
      String userId = payload['sub'].split(',')[0];
      print(userId);

      // Mengirim token ke server
      await sendTokenToServer(deviceToken, userId);
    } else {
      print('Access token tidak ditemukan');
    }
  }

  Future<void> sendTokenToServer(String deviceToken, String userId) async {
    final url =
        'http://10.0.2.2:8080/api/tokens'; // Ganti dengan URL endpoint Anda

    // Ambil access token dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $accessToken', // Menambahkan JWT token ke header
        },
        body: json.encode({
          'token': deviceToken,
          'userId': userId, // Kirim userId ke server
        }),
      );

      if (response.statusCode == 200) {
        print('Token berhasil disimpan di server');
      } else {
        print('Gagal menyimpan token: ${response.body}');
      }
    } catch (e) {
      print('Error saat mengirim token ke server: $e');
    }
  }

  void isTokenRefresh() async {
    messaging.onTokenRefresh.listen((event) {
      print('Token diperbarui: $event');
    }); // Mendengarkan token refresh
  }

  // Method untuk mendengarkan pesan
  void listenForMessages(String roomId, String senderId) {
    _messageSubscription = FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data() as Map<String, dynamic>;
          String messageContent = data['messageContent'];
          String messageSenderId = data['senderId'];

          // Beri tahu bagian lain dari aplikasi (Anda dapat menggunakan callback atau stream)
          if (messageSenderId != senderId) {
            showNotification('Pesan Baru', messageContent);
          }
        }
      }
    });
  }

  Future<void> sendNotification(
      String userId, String title, String body, String chatRoomId) async {
    final url = Uri.parse('$baseUrl/send-notification');

    // Ambil access token dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    final notificationRequest = NotificationRequest(
        userId: userId, title: title, body: body, chatRoomId: chatRoomId);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $accessToken', // Ganti dengan token akses yang valid
        },
        body: json.encode(notificationRequest.toJson()),
      );

      if (response.statusCode == 200) {
        print('Notifikasi berhasil dikirim');
      } else {
        print('Gagal mengirim notifikasi: ${response.body}');
      }
    } catch (e) {
      print('Error saat mengirim notifikasi: $e');
    }
  }
}
