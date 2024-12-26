import 'package:ssh_aplication/services/ApiConfig.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final WebSocketChannel channel;

  WebSocketService()
      : channel =
            WebSocketChannel.connect(Uri.parse(ApiConfig.websocketBaseUrl)) {
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
