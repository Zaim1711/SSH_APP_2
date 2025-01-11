class ApiConfig {
  // Ganti URL ini sesuai dengan URL API Anda
  static const String baseUrl = "http://10.0.2.2:8080";
  static const String websocketBaseUrl = "ws://10.0.2.2:8080/ws";
  //debug Handphone 192.168.68.246
  //debug Laptop 10.0.2.2

  //  Endpoint API with data
  static String getcheckUserUrl(String id) => "$baseUrl/details/user/$id";
  static String getFetchImage(String imageName) =>
      "$baseUrl/pengaduan/image/$imageName";
  static String getdetailsUser(id) => "$baseUrl/details/$id";
  static String deleteFcmToken(id) => "$baseUrl/api/tokens/$id";
  static String getDataUser(id) => "$baseUrl/users/$id";
  static String fetchChatRoomsBySender(id) =>
      "$baseUrl/api/chatrooms/sender/$id";
  static String fetchChatRoomsByReceiver(id) =>
      "$baseUrl/api/chatrooms/receiver/$id";
  static String createDetailsUser(id) => "$baseUrl/details?userId=$id";
  static String fetchPengaduanById(id) => "$baseUrl/pengaduan/user/$id";

  // Endpoint API
  static String get loginUrl => "$baseUrl/auth/login";
  static String get registerUrl => "$baseUrl/auth/register";
  static String get userProfileUrl => "$baseUrl/user/profile";
  static String get cretePengaduan => "$baseUrl/pengaduan/create";
  static String get saveUser => "$baseUrl/users";
  static String get fetchInformation => "$baseUrl/informasiHakHukum";
  static String get createRoom => "$baseUrl/api/chatrooms";
  static String get notificationService => "$baseUrl/api/tokens";
  static String get notificationServiceSend =>
      "$baseUrl/api/tokens/send-notification";
  static String get fetchUser => "$baseUrl/users";
  static String get detailsUser => "$baseUrl/details";
}
