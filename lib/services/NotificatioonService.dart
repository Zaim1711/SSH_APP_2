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
import 'package:ssh_aplication/package/UserPage/LandingPageChat.dart';
import 'package:ssh_aplication/services/ApiConfig.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  StreamSubscription? _messageSubscription;

  Future<void> init() async {
    // Inisialisasi notifikasi
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );

    // Membuat saluran notifikasi
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'your_channel_id',
      'Your Channel Name',
      description: 'Your channel description',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'your_channel_id',
      'Your Channel Name',
      channelDescription: 'Your channel description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformDetails,
      payload: 'default',
    );
  }

  Future<void> onSelectNotification(NotificationResponse response) async {
    final context = navigatorKey.currentContext;

    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LandingPageChatRooms(),
        ),
      );
    } else {
      print('Context tidak tersedia');
    }
  }

  void configureFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(
          message.notification!.title ?? 'Tanpa Judul',
          message.notification!.body ?? 'Tanpa Isi',
        );
      }

      if (message.data.isNotEmpty) {
        String senderId = message.data['senderId'] ?? 'Pengirim Tidak Dikenal';
        String messageContent =
            message.data['messageContent'] ?? 'Tanpa Konten';

        showNotification('Pesan Baru dari $senderId', messageContent);
      }
    });
  }

  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    if (message.notification != null) {
      final service = NotificationService();
      await service.showNotification(
        message.notification!.title ?? 'Tanpa Judul',
        message.notification!.body ?? 'Tanpa Isi',
      );
    }
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> requestNotificationPermission() async {
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
    }
  }

  Future<void> getDeviceToken() async {
    try {
      String? deviceToken = await messaging.getToken();
      if (deviceToken != null) {
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
      Map<String, dynamic> payload = JwtDecoder.decode(accessToken);
      String userId = payload['sub'].split(',')[0];
      await sendTokenToServer(deviceToken, userId);
    }
  }

  Future<void> sendTokenToServer(String deviceToken, String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.notificationService),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'token': deviceToken,
          'userId': userId,
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

          if (messageSenderId != senderId) {
            showNotification('Pesan Baru', messageContent);
          }
        }
      }
    });
  }

  Future<void> sendNotificationChat(
      String userId, String title, String body, String chatRoomId) async {
    final url = Uri.parse(ApiConfig.notificationServiceSend);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    final notificationRequest = NotificationRequest(
      userId: userId,
      title: title,
      body: body,
      chatRoomId: chatRoomId,
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
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

  Future<void> sendNotificationPengaduan(
      String adminId, String title, String body) async {
    final url = Uri.parse(ApiConfig.notificationServiceSend);

    // Ambil access token dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    final notificationRequest =
        NotificationRequest(userId: adminId, title: title, body: body);

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
