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
      
      // Gunakan URL API yang benar
      // Untuk emulator Android, gunakan 10.0.2.2 sebagai pengganti 127.0.0.1
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
        
        // Handle berbagai format respons API
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
      
      // Gunakan URL API yang benar
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
    required DateTime tanggalKembali,
    required int stok,
    required String keperluan,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Anda belum login. Silakan login terlebih dahulu.'
        };
      }
      
      // Format tanggal untuk API
      final dateFormat = DateFormat('yyyy-MM-dd');
      final formattedTanggalPinjam = dateFormat.format(tanggalPinjam);
      final formattedTanggalKembali = dateFormat.format(tanggalKembali);
      
      // Persiapkan data untuk dikirim
      final data = {
        'nama_peminjam': namaPeminjam,
        'barang_id': barangId.toString(), // Konversi ke string untuk API
        'tanggal_pinjam': formattedTanggalPinjam,
        'tanggal_kembali': formattedTanggalKembali,
        'stok': stok.toString(), // Konversi ke string untuk API
        'keperluan': keperluan,
      };
      
      print('Submitting peminjaman with data: $data');
      
      // Gunakan URL API yang benar
      final url = Uri.parse('http://127.0.0.1:8000/api/peminjamans');
      
      // Kirim request ke API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Peminjaman berhasil
        try {
          final responseData = jsonDecode(response.body);
          return {
            'success': true,
            'data': responseData,
            'message': 'Peminjaman berhasil diajukan'
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Peminjaman berhasil diajukan'
          };
        }
      } else {
        // Peminjaman gagal
        try {
          final responseData = jsonDecode(response.body);
          String message = 'Terjadi kesalahan saat mengajukan peminjaman';
          
          if (responseData is Map) {
            if (responseData.containsKey('message')) {
              message = responseData['message'].toString();
            } else if (responseData.containsKey('error')) {
              message = responseData['error'].toString();
            }
          }
          
          return {
            'success': false,
            'message': message
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Terjadi kesalahan: Status ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      print('Error creating peminjaman: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  Future<Map<String, dynamic>> ajukanPengembalian(
    dynamic peminjamanId, {
    required String namaPengembali,
    required DateTime tglKembali,
    required int jumlahKembali,
    required String kondisi,
    String? catatan,
  }) async {
    try { 
      // Format tanggal untuk API
      final dateFormat = DateFormat('yyyy-MM-dd');
      
      // Gunakan endpoint pengembalian yang benar
      final response = await _apiService.post(
        'pengembalian', // Endpoint yang benar
        {
          'nama_pengembali': namaPengembali,
          'id_peminjaman': peminjamanId.toString(),
          'tgl_kembali': dateFormat.format(tglKembali),
          'jumlah_kembali': jumlahKembali.toString(),
          'status': 'pending',
          'kondisi': kondisi,
          'catatan': catatan ?? '',
        },
        auth: true,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Pengembalian berhasil diajukan',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengajukan pengembalian',
        };
      }
    } catch (e) {
      print('Error ajukan pengembalian: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

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
}
