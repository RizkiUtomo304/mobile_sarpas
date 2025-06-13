import 'package:intl/intl.dart';
import 'barang.dart';
class Peminjaman {
  final int id;
  final String namaPeminjam;
  final int barangId;
  final DateTime tanggalPinjam;
  final DateTime? tanggalKembali; // Gunakan nullable type
  final int stok;
  final String status;
  final String? keperluan;
  final Barang? barang;

  Peminjaman({
    required this.id,
    required this.namaPeminjam,
    required this.barangId,
    required this.tanggalPinjam,
    this.tanggalKembali, // Nullable
    required this.stok,
    required this.status,
    this.keperluan,
    this.barang,
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    return Peminjaman(
      id: json['id'],
      namaPeminjam: json['nama_peminjam'],
      barangId: json['barang_id'],
      tanggalPinjam: DateTime.parse(json['tanggal_pinjam']),
      // Gunakan null check untuk tanggal_kembali
      tanggalKembali: json['tanggal_kembali'] != null ? 
                      DateTime.parse(json['tanggal_kembali']) : null,
      stok: int.parse(json['stok'].toString()),
      status: json['status'] ?? 'pending',
      keperluan: json['keperluan'],
      barang: json['barang'] != null ? Barang.fromJson(json['barang']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    return {
      'id': id,
      'nama_peminjam': namaPeminjam,
      'barang_id': barangId,
      'tanggal_pinjam': dateFormat.format(tanggalPinjam),
      'tanggal_kembali': tanggalKembali != null ? dateFormat.format(tanggalKembali!) : null,
      'stok': stok,
      'status': status,
      'keperluan': keperluan,
    };
  }

  // Getter untuk warna status
  int get statusColor {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return 0xFF4CAF50; // Green
      case 'pending':
      case 'menunggu':
        return 0xFFFFA000; // Amber
      case 'rejected':
      case 'ditolak':
        return 0xFFF44336; // Red
      case 'returned':
      case 'dikembalikan':
        return 0xFF2196F3; // Blue
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  // Getter untuk teks status yang lebih user-friendly
  String get statusText {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return 'Disetujui';
      case 'pending':
      case 'menunggu':
        return 'Menunggu';
      case 'rejected':
      case 'ditolak':
        return 'Ditolak';
      case 'returned':
      case 'dikembalikan':
        return 'Dikembalikan';
      default:
        return status;
    }
  }
}

