import 'package:intl/intl.dart';
import 'barang.dart';
class Peminjaman {
  final int id;
  final int? userId;  // Ubah ke nullable
  final String namaPeminjam;
  final int barangId;
  final DateTime tanggalPinjam;
  final DateTime? tanggalKembali;  // Ubah ke nullable
  final int stok;
  final String status;
  final String? keperluan;  // Tambahkan field keperluan
  final Barang? barang;

  Peminjaman({
    required this.id,
    this.userId,  // Ubah ke opsional
    required this.namaPeminjam,
    required this.barangId,
    required this.tanggalPinjam,
    this.tanggalKembali,  // Ubah ke opsional
    required this.stok,
    required this.status,
    this.keperluan,  // Tambahkan parameter
    this.barang,
  });

  factory Peminjaman.fromJson(Map<String, dynamic> json) {
    // Helper untuk mengkonversi nilai ke int dengan aman
    int safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }
    
    // Helper untuk mengkonversi nilai ke int nullable dengan aman
    int? safeParseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }
    
    // Helper untuk parsing tanggal dengan aman
    DateTime? parseTanggal(dynamic tanggal) {
      if (tanggal == null) return null;
      
      try {
        if (tanggal is String) {
          return DateTime.parse(tanggal);
        }
        return null;
      } catch (e) {
        print('Error parsing date: $e');
        return null;
      }
    }
    
    final tanggalPinjamParsed = parseTanggal(json['tanggal_pinjam']);
    final tanggalKembaliParsed = parseTanggal(json['tanggal_kembali']);
    
    return Peminjaman(
      id: safeParseInt(json['id']),
      userId: safeParseNullableInt(json['user_id']),
      namaPeminjam: json['nama_peminjam']?.toString() ?? '',
      barangId: safeParseInt(json['barang_id']),
      tanggalPinjam: tanggalPinjamParsed ?? DateTime.now(),
      tanggalKembali: tanggalKembaliParsed,
      stok: safeParseInt(json['stok']),
      status: json['status']?.toString() ?? 'pending',
      keperluan: json['keperluan']?.toString(),
      barang: json['barang'] != null ? Barang.fromJson(json['barang']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    return {
      'id': id,
      'user_id': userId,
      'nama_peminjam': namaPeminjam,
      'barang_id': barangId,
      'tanggal_pinjam': dateFormat.format(tanggalPinjam),
      'tanggal_kembali': tanggalKembali != null ? dateFormat.format(tanggalKembali!) : null,
      'stok': stok,
      'status': status,
      'keperluan': keperluan,
    };
  }

  // Helper untuk mendapatkan status dalam bahasa Indonesia
  String get statusText {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'approved':
      case 'diterima':
        return 'Disetujui';
      case 'rejected':
      case 'ditolak':
        return 'Ditolak';
      case 'borrowed':
      case 'dipinjam':
        return 'Sedang Dipinjam';
      case 'returned':
      case 'dikembalikan':
        return 'Sudah Dikembalikan';
      default:
        return status;
    }
  }

  // Helper untuk mendapatkan warna berdasarkan status
  int get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0xFFFFA000; // Amber
      case 'approved':
      case 'diterima':
        return 0xFF4CAF50; // Green
      case 'rejected':
      case 'ditolak':
        return 0xFFF44336; // Red
      case 'borrowed':
      case 'dipinjam':
        return 0xFF2196F3; // Blue
      case 'returned':
      case 'dikembalikan':
        return 0xFF4CAF50; // Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  // Helper untuk mengecek apakah peminjaman bisa dibatalkan
  bool get canBeCancelled {
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'pending';
  }
}

