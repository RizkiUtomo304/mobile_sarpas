import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/peminjaman.dart';
import 'api_service.dart';

class PeminjamanService {
  final ApiService _apiService = ApiService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // Mengambil daftar peminjaman pengguna
  Future<List<Peminjaman>> getPeminjaman() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Anda belum login. Silakan login terlebih dahulu.');
      }

      final url = Uri.parse('http://127.0.0.1:8000/api/peminjamans');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> peminjamanData;

        if (responseData is List) {
          peminjamanData = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          final dataContent = responseData['data'];
          if (dataContent is List) {
            peminjamanData = dataContent;
          } else {
            peminjamanData = [];
          }
        } else {
          peminjamanData = [];
        }

        return peminjamanData.map((item) => Peminjaman.fromJson(item)).toList();
      } else {
        throw Exception('Gagal mengambil data peminjaman: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPeminjaman: $e');
      throw Exception('Error: $e');
    }
  }

  // Mengambil detail peminjaman berdasarkan ID
  Future<Peminjaman> getPeminjamanById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Anda belum login. Silakan login terlebih dahulu.');
      }

      final url = Uri.parse('http://127.0.0.1:8000/api/peminjamans/$id');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Peminjaman.fromJson(data);
      } else {
        throw Exception('Gagal mengambil detail peminjaman: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getPeminjamanById: $e');
      throw Exception('Error: $e');
    }
  }

  // Membuat peminjaman baru
  Future<Map<String, dynamic>> createPeminjaman({
    required String namaPeminjam,
    required int barangId,
    required DateTime tanggalPinjam,
    required int stok,
    required String keperluan,
  }) async {
    try {
      final formattedTanggalPinjam = _dateFormat.format(tanggalPinjam);

      final data = {
        'nama_peminjam': namaPeminjam,
        'barang_id': barangId.toString(),
        'tanggal_pinjam': formattedTanggalPinjam,
        'stok': stok.toString(),
        'keperluan': keperluan,
      };

      print('Sending data to API: $data');

      final response = await _apiService.post(
        'peminjamans',
        data,
        auth: true,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Peminjaman berhasil dibuat',
          'data': responseData
        };
      } else {
        String message = 'Gagal membuat peminjaman';
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map && responseData.containsKey('message')) {
            message = responseData['message'];
          }
        } catch (e) {
          print('Error parsing response: $e');
        }

        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      print('Error creating peminjaman: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Mengajukan pengembalian
  Future<Map<String, dynamic>> ajukanPengembalian(
    dynamic peminjamanId, {
    required String namaPengembali,
    required DateTime tglKembali,
    required int jumlahKembali,
    required String kondisi,
    String? catatan,
  }) async {
    try {
      final formattedTglKembali = _dateFormat.format(tglKembali);

      final payload = {
        'nama_pengembali': namaPengembali,
        'id_peminjaman': peminjamanId.toString(),
        'tanggal_kembali': formattedTglKembali,
        'jumlah_kembali': jumlahKembali.toString(),
        'kondisi': kondisi.toLowerCase(),
        'catatan': catatan ?? '',
      };

      print('Sending payload to API: $payload');

      final response = await _apiService.post(
        'pengembalian',
        payload,
        auth: true,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.body == null || response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Respons kosong dari server',
        };
      }

      try {
        final responseData = jsonDecode(response.body);

        if (responseData is! Map) {
          return {
            'success': false,
            'message': 'Format respons tidak valid',
          };
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {
            'success': true,
            'message': 'Pengembalian berhasil diajukan',
            'data': responseData
          };
        } else {
          String message = 'Gagal mengajukan pengembalian';
          if (responseData.containsKey('message')) {
            message = responseData['message'].toString();
          }

          return {
            'success': false,
            'message': message,
          };
        }
      } catch (e) {
        print('Error parsing response: $e');
        return {
          'success': false,
          'message': 'Gagal memproses respons: $e',
        };
      }
    } catch (e) {
      print('Error submitting pengembalian: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Mendapatkan detail peminjaman
  Future<Map<String, dynamic>> getPeminjamanDetail(int peminjamanId) async {
    try {
      final response = await _apiService.get(
        'peminjamans/$peminjamanId',
        auth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data is Map ? data : (data is List && data.isNotEmpty ? data[0] : null),
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mendapatkan detail peminjaman',
        };
      }
    } catch (e) {
      print('Error getting peminjaman detail: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Mendapatkan daftar pengembalian
  Future<Map<String, dynamic>> getPengembalian() async {
    try {
      final response = await _apiService.get(
        'pengembalian',
        auth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data is Map && data.containsKey('data') ? data['data'] : data,
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mendapatkan daftar pengembalian',
        };
      }
    } catch (e) {
      print('Error getting pengembalian list: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Alternatif pengajuan pengembalian
  Future<Map<String, dynamic>> ajukanPengembalianAlternatif(
    dynamic peminjamanId, {
    required String namaPengembali,
    required DateTime tglKembali,
    required int jumlahKembali,
    required String kondisi,
    String? catatan,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Anda belum login. Silakan login terlebih dahulu.');
      }

      final formattedTglKembali = _dateFormat.format(tglKembali);

      final Map<String, String> payload = {
        'nama_pengembali': namaPengembali,
        'id_peminjaman': peminjamanId.toString(),
        'tanggal_kembali': formattedTglKembali,
        'jumlah_kembali': jumlahKembali.toString(),
        'status': 'pending',
        'kondisi': kondisi.toLowerCase(),
      };

      if (catatan != null && catatan.isNotEmpty) {
        payload['catatan'] = catatan;
      }

      print('Sending direct HTTP request with payload: $payload');

      final url = Uri.parse('http://127.0.0.1:8000/api/pengembalian');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: payload,
      );

      print('Direct HTTP response status: ${response.statusCode}');
      print('Direct HTTP response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Pengembalian berhasil diajukan',
          'data': responseData
        };
      } else {
        String message = 'Gagal mengajukan pengembalian';
        try {
          final responseData = jsonDecode(response.body);
          if (responseData is Map && responseData.containsKey('message')) {
            message = responseData['message'];
          }
        } catch (e) {
          print('Error parsing response: $e');
        }

        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      print('Error in ajukanPengembalianAlternatif: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
