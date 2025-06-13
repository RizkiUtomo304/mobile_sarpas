import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PengembalianService {
  final String baseUrl = 'http://127.0.0.1:8000/api'; // Sesuaikan dengan URL API Anda
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  Future<Map<String, dynamic>> ajukanPengembalian({
    required String peminjamanId,
    required String namaPengembali,
    required DateTime tanggalKembali,
    required int jumlahKembali,
    required String kondisi,
    String? catatan,
  }) async {
    try {
      // Dapatkan token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Anda belum login. Silakan login terlebih dahulu.',
        };
      }

      // Format tanggal dengan benar
      final formattedTanggalKembali = _dateFormat.format(tanggalKembali);
      
      // Buat body request dengan nama field yang benar
      final Map<String, dynamic> body = {
        'id_peminjaman': peminjamanId,
        'nama_pengembali': namaPengembali,
        'tgl_kembali': formattedTanggalKembali, // Gunakan tgl_kembali, bukan tanggal_kembali
        'jumlah_kembali': jumlahKembali.toString(),
        'kondisi': kondisi,
      };

      if (catatan != null && catatan.isNotEmpty) {
        body['catatan'] = catatan;
      }
      
      print('Request body: $body');
      
      // Kirim request
      final response = await http.post(
        Uri.parse('$baseUrl/pengembalian'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          return http.Response('{"success":false,"message":"Timeout: Server tidak merespons"}', 408);
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      // Pastikan response body tidak kosong
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Server mengembalikan respons kosong',
        };
      }
      
      // Parse response dengan aman
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('Error parsing JSON: $e');
        return {
          'success': false,
          'message': 'Format respons tidak valid: ${response.body}',
        };
      }
      
      // Parse response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Sukses
        return {
          'success': true,
          'message': responseData['message'] ?? 'Pengembalian berhasil diajukan',
          'data': responseData['data'],
        };
      } else {
        // Gagal
        String message = 'Gagal mengajukan pengembalian';
        
        if (responseData.containsKey('message')) {
          message = responseData['message'];
        }
        
        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      print('Error in ajukanPengembalian: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}






