import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/barang.dart';

// Ubah URL API sesuai dengan endpoint yang benar di server Laravel
const String baseUrl = "http://127.0.0.1:8000/api";  // Pastikan port ini benar

class ApiService {
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  Future<Map<String, String>> getHeaders({bool auth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // Tambahkan fungsi untuk menguji koneksi
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ping'),
        headers: await getHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      print('Test connection response: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Ambil daftar barang
  Future<List<Barang>> getBarang() async {
    try {
      final url = Uri.parse('$baseUrl/barangs'); // Gunakan endpoint yang benar
      final headers = await getHeaders(auth: true);
      
      print('Fetching barang from: $url');
      print('Headers: $headers');
      
      final response = await http.get(url, headers: headers);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return _parseBarangResponse(response.body);
      } else {
        throw Exception('Gagal mengambil data barang: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getBarang: $e');
      throw Exception('Error: $e');
    }
  }

  // Tambahkan fungsi helper untuk parsing data dengan aman
  dynamic safeParseData(dynamic data) {
    if (data is Map && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  List<Barang> _parseBarangResponse(String responseBody) {
    final data = jsonDecode(responseBody);
    
    // Handle berbagai format respons API
    List<dynamic> barangList;
    if (data is List) {
      barangList = data;
    } else if (data is Map) {
      // Pastikan data['data'] adalah List
      final dataContent = data['data'];
      if (dataContent is List) {
        barangList = dataContent;
      } else {
        barangList = [];
      }
    } else {
      barangList = [];
    }
    
    return barangList.map((item) => Barang.fromJson(item)).toList();
  }

  // Metode HTTP generik dengan error handling
  Future<http.Response> post(String endpoint, Map<String, dynamic> data, {bool auth = false}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await getHeaders(auth: auth);
      
      print('POST request to: $url');
      print('Headers: $headers');
      print('Body: $data');
      
      final response = await http.post(
        url, 
        headers: headers, 
        body: jsonEncode(data),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response;
    } catch (e) {
      print('Error in POST request: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> get(String endpoint, {bool auth = false}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await getHeaders(auth: auth);
      
      print('GET request to: $url');
      print('Headers: $headers');
      
      final response = await http.get(url, headers: headers);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response;
    } catch (e) {
      print('Error in GET request: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data, {bool auth = false}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await getHeaders(auth: auth);
      
      print('PUT request to: $url');
      print('Headers: $headers');
      print('Body: $data');
      
      final response = await http.put(
        url, 
        headers: headers, 
        body: jsonEncode(data),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response;
    } catch (e) {
      print('Error in PUT request: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<http.Response> delete(String endpoint, {bool auth = false}) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final headers = await getHeaders(auth: auth);
      
      print('DELETE request to: $url');
      print('Headers: $headers');
      
      final response = await http.delete(url, headers: headers);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      return response;
    } catch (e) {
      print('Error in DELETE request: $e');
      throw Exception('Network error: $e');
    }
  }

  // Tambahkan metode getKategori() di ApiService
  Future<List<String>> getKategori() async {
    try {
      final response = await get('kategori', auth: true);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map<String>((item) => item['nama_kategori'] as String).toList();
      } else {
        throw Exception('Gagal memuat kategori: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getKategori: $e');
      return []; // Return empty list on error
    }
  }
}
