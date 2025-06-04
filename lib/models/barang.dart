// lib/models/barang.dart
class Barang {
  final int id;
  final String nama;
  final int stok;
  final String? foto;
  final String kategori;

  Barang({
    required this.id,
    required this.nama,
    required this.stok,
    this.foto,
    required this.kategori,
  });

  factory Barang.fromJson(Map<String, dynamic> json) {
    // Pastikan semua field ada dan memiliki tipe yang benar
    return Barang(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nama: json['nama'] ?? 'Tidak ada nama',
      stok: json['stok'] is int ? json['stok'] : int.parse((json['stok'] ?? '0').toString()),
      foto: json['foto'],
      kategori: json['kategori'] is Map 
          ? json['kategori']['nama_kategori'] ?? 'Tidak ada kategori'
          : json['nama_kategori'] ?? 'Tidak ada kategori',
    );
  }

  String get fullImageUrl {
    if (foto == null || foto!.isEmpty) {
      return 'https://via.placeholder.com/150';
    }
    
    // Jika foto sudah berupa URL lengkap, gunakan langsung
    if (foto!.startsWith('http://') || foto!.startsWith('https://')) {
      return foto!;
    }
    
    // Jika foto adalah path relatif, gabungkan dengan base URL
    // Ganti dengan URL server yang sesuai
    return 'http://127.0.0.1:8000/${foto!.replaceFirst('/', '')}';
  }
}
