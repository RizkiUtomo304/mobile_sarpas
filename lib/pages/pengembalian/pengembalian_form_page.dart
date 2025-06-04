import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/peminjaman_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class PengembalianFormPage extends StatefulWidget {
  final dynamic peminjamanId;
  const PengembalianFormPage({Key? key, required this.peminjamanId}) : super(key: key);
  
  @override
  State<PengembalianFormPage> createState() => _PengembalianFormPageState();
}

class _PengembalianFormPageState extends State<PengembalianFormPage> {
  final PeminjamanService service = PeminjamanService();
  final _formKey = GlobalKey<FormState>();
  final _namaPengembaliController = TextEditingController();
  final _jumlahKembaliController = TextEditingController(text: '1');
  final _catatanController = TextEditingController();
  
  bool _isLoading = false;
  String _kondisi = 'baik';
  DateTime _tglKembali = DateTime.now();
  
  // Tambahkan variabel untuk menyimpan detail peminjaman
  Map<String, dynamic>? _peminjamanDetail;
  
  // Warna tema
  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color secondaryColor = const Color(0xFFD1C4E9);
  
  // Tambahkan variabel yang hilang
  String? _errorMessage;
  int _jumlahKembali = 1;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPeminjamanDetail();
  }
  
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      
      if (username != null && username.isNotEmpty) {
        setState(() {
          _namaPengembaliController.text = username;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }
  
  // Fungsi untuk mengkonversi ID dengan aman
  int _getPeminjamanId() {
    if (widget.peminjamanId is int) {
      return widget.peminjamanId;
    }
    
    if (widget.peminjamanId is String) {
      try {
        return int.parse(widget.peminjamanId);
      } catch (e) {
        print('Error parsing peminjamanId: $e');
        return 0;
      }
    }
    
    return 0;
  }
  
  Future<void> _loadPeminjamanDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }
      
      // Gunakan URL yang benar untuk emulator Android
      final baseUrl = 'http://127.0.0.1:8000/api';
      final peminjamanId = _getPeminjamanId();
      
      print('Mencoba mengakses: $baseUrl/peminjamans/$peminjamanId');
      print('Token: $token');
      
      final response = await http.get(
        Uri.parse('$baseUrl/peminjamans/$peminjamanId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Langsung parse data tanpa mengakses 'data'
        final data = jsonDecode(response.body);
        setState(() {
          _peminjamanDetail = data;
          _isLoading = false;
          
          // Set jumlah kembali berdasarkan stok
          if (_peminjamanDetail != null && _peminjamanDetail!.containsKey('stok')) {
            _jumlahKembali = int.tryParse(_peminjamanDetail!['stok'].toString()) ?? 1;
            _jumlahKembaliController.text = _jumlahKembali.toString();
          }
        });
      } else {
        throw Exception('Gagal memuat data: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Tidak dapat terhubung ke server. Pastikan server berjalan.';
      });
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Koneksi timeout. Server terlalu lama merespon.';
      });
    } on http.ClientException catch (e) {
      print('ClientException: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal terhubung ke server: ${e.message}';
      });
    } catch (e) {
      print('Error lainnya: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }
  
  Future<void> _ajukanPengembalian() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Gunakan URL yang benar
      final baseUrl = 'http://127.0.0.1:8000/api';
      final peminjamanId = _getPeminjamanId();
      
      print('Mengajukan pengembalian untuk ID: $peminjamanId');
      print('Token: $token');
      
      // Siapkan data untuk dikirim - sesuaikan dengan format yang diharapkan API
      final data = {
        'id_peminjaman': peminjamanId,  // Sesuaikan nama field dengan API
        'nama_pengembali': _namaPengembaliController.text,
        'tgl_kembali': DateFormat('yyyy-MM-dd').format(_tglKembali),
        'jumlah_kembali': _jumlahKembaliController.text,  // Kirim sebagai string
        'kondisi': _kondisi,
        'catatan': _catatanController.text,
      };
      
      print('Data yang dikirim: $data');
      
      final response = await http.post(
        Uri.parse('$baseUrl/pengembalian'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengembalian berhasil diajukan'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      } else {
        // Coba parse error message dari response
        String errorMessage = 'Terjadi kesalahan saat mengajukan pengembalian';
        try {
          Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData.containsKey('message')) {
            errorMessage = responseData['message'];
          } else if (responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          }
        } catch (e) {
          print('Error parsing response: $e');
        }
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saat mengajukan pengembalian: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Form Pengembalian',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildForm(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPeminjamanDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    // Implementasi form pengembalian
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form fields
            TextFormField(
              controller: _namaPengembaliController,
              decoration: InputDecoration(
                labelText: 'Nama Pengembali',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama pengembali tidak boleh kosong';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Tanggal Kembali
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _tglKembali,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _tglKembali = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tanggal Kembali',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy').format(_tglKembali),
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Jumlah Kembali
            TextFormField(
              controller: _jumlahKembaliController,
              decoration: InputDecoration(
                labelText: 'Jumlah Kembali',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah kembali tidak boleh kosong';
                }
                try {
                  int jumlah = int.parse(value);
                  if (jumlah <= 0) {
                    return 'Jumlah kembali harus lebih dari 0';
                  }
                  if (_peminjamanDetail != null && 
                      _peminjamanDetail!.containsKey('jumlah') && 
                      jumlah > _peminjamanDetail!['jumlah']) {
                    return 'Jumlah kembali tidak boleh lebih dari jumlah pinjam';
                  }
                } catch (e) {
                  return 'Jumlah kembali harus berupa angka';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            
            // Kondisi
            Text('Kondisi Barang', style: TextStyle(fontSize: 16)),
            Row(
              children: [
                Radio<String>(
                  value: 'baik',
                  groupValue: _kondisi,
                  onChanged: (value) {
                    setState(() {
                      _kondisi = value!;
                    });
                  },
                ),
                Text('Baik'),
                SizedBox(width: 16),
                Radio<String>(
                  value: 'rusak',
                  groupValue: _kondisi,
                  onChanged: (value) {
                    setState(() {
                      _kondisi = value!;
                    });
                  },
                ),
                Text('Rusak'),
                SizedBox(width: 16),
                Radio<String>(
                  value: 'hilang',
                  groupValue: _kondisi,
                  onChanged: (value) {
                    setState(() {
                      _kondisi = value!;
                    });
                  },
                ),
                Text('Hilang'),
              ],
            ),
            SizedBox(height: 16),
            
            // Catatan
            TextFormField(
              controller: _catatanController,
              decoration: InputDecoration(
                labelText: 'Catatan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _ajukanPengembalian,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Ajukan Pengembalian',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
