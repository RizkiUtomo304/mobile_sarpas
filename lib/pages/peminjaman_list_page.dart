import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class PeminjamanListPage extends StatefulWidget {
  const PeminjamanListPage({Key? key}) : super(key: key);

  @override
  State<PeminjamanListPage> createState() => _PeminjamanListPageState();
}

class _PeminjamanListPageState extends State<PeminjamanListPage> {
  final Color primaryColor = const Color(0xFF6A1B9A); // Ungu tua
  final Color secondaryColor = const Color(0xFFD1C4E9); // Ungu muda

  bool isLoading = true;
  List<dynamic> peminjamanList = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Inisialisasi format tanggal untuk bahasa Indonesia
    initializeDateFormatting('id_ID', null).then((_) {
      _loadPeminjamanData();
    });
  }

  Future<void> _loadPeminjamanData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Anda belum login. Silakan login terlebih dahulu.';
          isLoading = false;
        });
        return;
      }

      final url = Uri.parse('http://127.0.0.1:8000/api/peminjamans');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          List<dynamic> peminjamanData = [];
          
          if (responseData is Map && responseData.containsKey('data')) {
            final dataContent = responseData['data'];
            if (dataContent is List) {
              peminjamanData = dataContent;
            } else {
              print('Warning: data is not a List: ${dataContent.runtimeType}');
              peminjamanData = [];
            }
          } else if (responseData is List) {
            peminjamanData = responseData;
          }
          
          setState(() {
            peminjamanList = peminjamanData;
            isLoading = false;
          });
        } catch (e) {
          print('Error parsing response: $e');
          setState(() {
            errorMessage = 'Terjadi kesalahan saat memproses data: $e';
            isLoading = false;
          });
        }
      } else {
        // Handle error response
        try {
          final data = jsonDecode(response.body);
          setState(() {
            errorMessage = data['message']?.toString() ?? 'Terjadi kesalahan saat memuat data';
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            errorMessage = 'Terjadi kesalahan saat memproses respons: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _cancelPeminjaman(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda belum login. Silakan login terlebih dahulu.')),
        );
        return;
      }

      // Ganti URL dengan URL API yang benar
      final url = Uri.parse('http://127.0.0.1:8000/api/peminjamans/$id/cancel');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peminjaman berhasil dibatalkan')),
        );
        _loadPeminjamanData(); // Refresh data
      } else {
        try {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Gagal membatalkan peminjaman')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membatalkan peminjaman: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'borrowed':
        return 'Sedang Dipinjam';
      case 'returned':
        return 'Dikembalikan';
      case 'cancelled':
        return 'Dibatalkan';
      case 'late':
        return 'Terlambat';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'borrowed':
        return Colors.green;
      case 'returned':
        return Colors.teal;
      case 'cancelled':
        return Colors.grey;
      case 'late':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'borrowed':
        return Icons.inventory_2;
      case 'returned':
        return Icons.assignment_turned_in;
      case 'cancelled':
        return Icons.block;
      case 'late':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daftar Peminjaman',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPeminjamanData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, secondaryColor.withOpacity(0.3)],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            errorMessage!,
                            style: GoogleFonts.poppins(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPeminjamanData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Coba Lagi',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                    ),
                  )
                : peminjamanList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada peminjaman',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Anda belum melakukan peminjaman barang',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPeminjamanData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: peminjamanList.length,
                          itemBuilder: (context, index) {
                            final item = peminjamanList[index];
                            final status = item['status'] ?? 'pending';
                            final barang = item['barang'] ?? {'nama': 'Barang tidak diketahui'};
                            
                            // Gunakan try-catch untuk menghindari error parsing tanggal
                            String tanggalPinjam = '-';
                            String tanggalKembali = '-';
                            
                            try {
                              if (item['tanggal_pinjam'] != null) {
                                tanggalPinjam = DateFormat('dd MMMM yyyy', 'id_ID')
                                    .format(DateTime.parse(item['tanggal_pinjam']));
                              }
                            } catch (e) {
                              print('Error parsing tanggal_pinjam: $e');
                            }
                            
                            try {
                              if (item['tanggal_kembali'] != null) {
                                tanggalKembali = DateFormat('dd MMMM yyyy', 'id_ID')
                                    .format(DateTime.parse(item['tanggal_kembali']));
                              }
                            } catch (e) {
                              print('Error parsing tanggal_kembali: $e');
                            }
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tambahkan gambar barang di bagian atas card
                                  if (barang != null && barang['foto'] != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                      child: Image.network(
                                        _getFullImageUrl(barang['foto']),
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            height: 180,
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 180,
                                            width: double.infinity,
                                            color: Colors.grey[100],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded / 
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                                color: primaryColor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      // Konten card yang sudah ada
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(status).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: _getStatusColor(status)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _getStatusIcon(status),
                                                    size: 16,
                                                    color: _getStatusColor(status),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    _getStatusText(status),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: _getStatusColor(status),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '#${item['id'] ?? ''}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          barang['nama'] ?? 'Barang tidak diketahui',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Jumlah: ${item['jumlah'] ?? 0} ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Tanggal Pinjam',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    tanggalPinjam,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Tanggal Kembali',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                    tanggalKembali,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item['kepentingan'] != null && item['kepentingan'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 16),
                                          Text(
                                            'Kepentingan:',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            item['kepentingan'].toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                        // Menghapus blok kode untuk tombol Batalkan Peminjaman
                                        // if (status.toLowerCase() == 'pending') ... blok dihapus
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  String _getFullImageUrl(String? foto) {
    if (foto == null || foto.isEmpty) {
      return 'https://via.placeholder.com/150';
    }
    
    // Jika foto sudah berupa URL lengkap, gunakan langsung
    if (foto.startsWith('http://') || foto.startsWith('https://')) {
      return foto;
    }
    
    // Jika foto adalah path relatif, gabungkan dengan base URL
    return 'http://127.0.0.1:8000/${foto.replaceFirst('/', '')}';
  }
}

// Fungsi untuk menggabungkan URL dasar dengan path foto
String _getFullImageUrl(String imagePath) {
  const baseUrl = 'http://127.0.0.1:8000/storage/'; // Ganti dengan URL dasar yang benar
  return '$baseUrl$imagePath';
}




