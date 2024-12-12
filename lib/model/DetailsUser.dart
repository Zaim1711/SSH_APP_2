class DetailsUser {
  final int id;
  final String nik;
  final String alamat;
  final String nomorTelepon; // Menggunakan camelCase untuk konvensi penamaan
  final String userId;

  DetailsUser({
    required this.id,
    required this.nik,
    required this.alamat,
    required this.nomorTelepon,
    required this.userId,
  });

  factory DetailsUser.fromJson(Map<String, dynamic> json) {
    return DetailsUser(
      id: json['id'],
      nik: json['nik']?.toString() ?? '', // Menggunakan null-aware operator
      alamat: json['alamat'] ?? '', // Menggunakan null-aware operator
      nomorTelepon: json['nomor_telepon']?.toString() ??
          '', // Menggunakan null-aware operator
      userId: json['userId'] ?? '', // Menggunakan null-aware operator
    );
  }
}
