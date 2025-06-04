import 'package:intl/intl.dart';
import 'peminjaman.dart';

class Pengembalian {
  final int id;
  final String namaPengembali;
  final int idPeminjaman;
  final DateTime tglKembali;
  final int jumlahKembali;
  final String status;
  final String kondisi;
  final double biayaDenda;
  final Peminjaman? peminjaman;

  Pengembalian({
    required this.id,
    required this.namaPengembali,
    required this.idPeminjaman,
    required this.tglKembali,
    required this.jumlahKembali,
    required this.status,
    required this.kondisi,
    this.biayaDenda = 0,
    this.peminjaman,
  });

  factory Pengembalian.fromJson(Map<String, dynamic> json) {
    // Helper untuk mengkonversi nilai ke int dengan aman
    int safeParseInt(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }
    
    // Helper untuk mengkonversi nilai ke double dengan aman
    double safeParseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
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
    
    final tglKembaliParsed = parseTanggal(json['tgl_kembali']);
    
    return Pengembalian(
      id: safeParseInt(json['id']),
      namaPengembali: json['nama_pengembali']?.toString() ?? '',
      idPeminjaman: safeParseInt(json['id_peminjaman']),
      tglKembali: tglKembaliParsed ?? DateTime.now(),
      jumlahKembali: safeParseInt(json['jumlah_kembali']),
      status: json['status']?.toString() ?? 'pending',
      kondisi: json['kondisi']?.toString() ?? 'baik',
      biayaDenda: safeParseDouble(json['biaya_denda']),
      peminjaman: json['peminjaman'] != null ? Peminjaman.fromJson(json['peminjaman']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    return {
      'id': id,
      'nama_pengembali': namaPengembali,
      'id_peminjaman': idPeminjaman,
      'tgl_kembali': dateFormat.format(tglKembali),
      'jumlah_kembali': jumlahKembali,
      'status': status,
      'kondisi': kondisi,
      'biaya_denda': biayaDenda,
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
      case 'returned':
      case 'dikembalikan':
        return 'Sudah Dikembalikan';
      default:
        return status;
    }
  }

  // Helper untuk mendapatkan kondisi dalam bahasa Indonesia
  String get kondisiText {
    switch (kondisi.toLowerCase()) {
      case 'baik':
        return 'Baik';
      case 'rusak':
        return 'Rusak';
      case 'hilang':
        return 'Hilang';
      default:
        return kondisi;
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
      case 'returned':
      case 'dikembalikan':
        return 0xFF4CAF50; // Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  // Helper untuk mendapatkan warna berdasarkan kondisi
  int get kondisiColor {
    switch (kondisi.toLowerCase()) {
      case 'baik':
        return 0xFF4CAF50; // Green
      case 'rusak':
        return 0xFFFFA000; // Amber
      case 'hilang':
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  // Helper untuk format biaya denda
  String get formattedBiayaDenda {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormat.format(biayaDenda);
  }
}