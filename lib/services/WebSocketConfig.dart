import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final WebSocketChannel channel;

  // URL WebSocket langsung ditulis di sini
  static const String webSocketUrl = "ws://10.0.2.2:8080/location";

  WebSocketService()
      : channel = WebSocketChannel.connect(Uri.parse(webSocketUrl)) {
    print(
        "WebSocket URL: $webSocketUrl"); // Menambahkan print untuk mencetak URL

    channel.stream.listen((message) {
      print("Received message: $message");
    }, onDone: () {
      print("WebSocket connection closed");
    }, onError: (error) {
      print("WebSocket error: $error");
    });
  }

  void sendMessage(String message) {
    channel.sink.add(message);
    print("Message sent: $message");
  }

  void close() {
    channel.sink.close();
  }
}
