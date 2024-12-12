class Informasihakdanhukum {
  final int id;
  final String judul;
  final String deskripsi;

  Informasihakdanhukum({
    required this.id,
    required this.judul,
    required this.deskripsi,
  });

  factory Informasihakdanhukum.fromJson(Map<String, dynamic> json) {
    return Informasihakdanhukum(
      id: json['id'],
      judul: json['judul'],
      deskripsi: json['deskripsi'],
    );
  }
}
