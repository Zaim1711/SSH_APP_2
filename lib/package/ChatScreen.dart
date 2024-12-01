import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ssh_aplication/model/userModel.dart';
import 'package:ssh_aplication/services/NotificatioonService.dart'; // Pastikan untuk mengimpor NotificationService

class Chatscreen extends StatefulWidget {
  final User user;
  final String roomId;
  final String senderId;

  Chatscreen({
    Key? key,
    required this.user,
    required this.roomId,
    required this.senderId,
  }) : super(key: key);

  @override
  _ChatscreenState createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> {
  final TextEditingController _messageInputController = TextEditingController();
  final List<String> messages = [];
  Map<String, dynamic> payload = {};
  String userName = '';
  String userId = '';
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  final ScrollController _scrollController = ScrollController();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _picker = ImagePicker();
  bool _isPickingMedia = false;

  @override
  void initState() {
    super.initState();
    _getUserIdFromToken();
    listenForMessages();
    _notificationService.init(); // Inisialisasi notifikasi
    _notificationService.configureFCM(); // Konfigurasi FCM
  }

  Future<void> _getUserIdFromToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accesToken');

    if (accessToken != null) {
      payload = JwtDecoder.decode(accessToken);
      String name = payload['sub'].split(',')[2];
      String id = payload['sub'].split(',')[0];
      // Mengambil nilai 'name' dari token JWT
      setState(() {
        userName = name;
        userId = id;
      });
    }
  }

  Future<void> _pickMedia() async {
    if (_isPickingMedia) return;

    _isPickingMedia = true;

    // Tampilkan dialog untuk memilih antara kamera atau galeri
    final String? source = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Sumber Gambar'),
          actions: <Widget>[
            TextButton(
              child: Text('Ambil Foto'),
              onPressed: () {
                Navigator.of(context).pop('camera'); // Mengembalikan 'camera'
              },
            ),
            TextButton(
              child: Text('Pilih dari Galeri'),
              onPressed: () {
                Navigator.of(context).pop('gallery'); // Mengembalikan 'gallery'
              },
            ),
          ],
        );
      },
    );

    if (source == null) {
      _isPickingMedia =
          false; // Reset status jika tidak ada sumber yang dipilih
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );

      if (pickedFile != null) {
        File file = File(pickedFile.path);
        _showImagePreviewDialog(file);
      }
    } catch (e) {
      print('Error picking media: $e');
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<String?> _uploadFile(File file) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = FirebaseStorage.instance.ref().child('uploads/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl; // Mengembalikan URL unduhan
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  void listenForMessages() {
    _messageSubscription = FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data() as Map<String, dynamic>;
          String messageContent = data['messageContent'];
          String senderId = data['senderId'];
          String timestamp = data['timestamp'];
          String chatRoomId = data['chatRoomId']; // Masih ada di sini
          bool isRead = data['isRead'] ?? false;

          setState(() {
            messages.add(
                "$messageContent - ${DateFormat('HH:mm').format(DateTime.parse(timestamp))} - $senderId - Chat Room: $chatRoomId - ${isRead ? '✔️' : '✖️'}");
          });
          _scrollToBottom();
        }
      }
    });
  }

  void sendMessage(String messageContent) {
    if (messageContent.isNotEmpty) {
      String messageId = FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(widget.roomId)
          .collection('messages')
          .doc()
          .id;

      Map<String, dynamic> message = {
        'messageId': messageId,
        'chatRoomId': widget.roomId,
        'messageContent': messageContent,
        'senderId': widget.senderId,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      };

      FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(widget.roomId)
          .collection('messages')
          .doc(messageId)
          .set(message)
          .then((_) {
        print(
            'Message sent to Firestore successfully! Document ID: $messageId');

        // Kirim notifikasi ke pengguna lain
        String receiverId = widget.user.id
            .toString(); // Ganti dengan ID pengguna yang akan menerima notifikasi
        String senderName = userName;
        String chatRoomId = widget.roomId;
        print(userName);

        _notificationService.sendNotification(
          receiverId,
          senderName,
          messageContent,
          chatRoomId,
        );

        _scrollToBottom();
      }).catchError((error) {
        print('Failed to send message to Firestore: $error');
      });

      _messageInputController.clear();
    }
  }

  void _showImagePreviewDialog(File file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Preview Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(file), // Tampilkan gambar
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // 1. Unggah gambar ke Firebase Storage
                String? downloadUrl = await _uploadFile(file);

                // 2. Jika URL berhasil didapatkan, kirim sebagai pesan
                if (downloadUrl != null) {
                  sendMessage(downloadUrl); // Mengirim URL gambar sebagai pesan
                }

                // 3. Tutup dialog
                Navigator.of(context).pop(); // Tutup dialog

                // 4. Reset status
                _isPickingMedia = false; // Reset status setelah dialog ditutup
              },
              child: Text('Kirim'),
            ),
            TextButton(
              onPressed: () {
                // Tutup dialog tanpa mengirim
                Navigator.of(context).pop(); // Tutup dialog
                _isPickingMedia = false; // Reset status setelah dialog ditutup
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.username}'),
        actions: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: _pickMedia, // Memanggil fungsi untuk memilih media
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _buildMessageList(),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageInputController,
                    decoration: const InputDecoration(
                      labelText: 'Masukkan pesan',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    String messageContent = _messageInputController.text;
                    sendMessage(messageContent);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(widget.roomId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Belum ada pesan.'));
        }

        final messages = snapshot.data!.docs;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final messageContent = messageData['messageContent'];
            final senderId = messageData['senderId'];
            final timestamp = messageData['timestamp'];
            final isRead = messageData['isRead'] ?? false;
            final messageId = messageData['messageId'];

            return GestureDetector(
              onTap: () {
                if (senderId != widget.senderId) {
                  markMessageAsRead(messageId);
                }
              },
              child: Align(
                alignment: senderId == widget.senderId
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: MessageBubble(
                  message:
                      "$messageContent - ${DateFormat('HH:mm').format(DateTime.parse(timestamp))} ",
                  // - ${isRead ? '✔️' : '✖️'}
                  isSender: senderId == widget.senderId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void markMessageAsRead(String messageId) {
    FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(widget.roomId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true}).then((_) {
      print('Message marked as read successfully!');
    }).catchError((error) {
      print('Failed to mark message as read: ${error.message}');
    });
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSender;

  const MessageBubble({Key? key, required this.message, required this.isSender})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isSender ? Colors.blueAccent : Colors.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.white),
        softWrap: true,
      ),
    );
  }
}
