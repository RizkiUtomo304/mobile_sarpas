import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/api_service.dart';

class RiwayatPeminjamanPage extends StatefulWidget {
  const RiwayatPeminjamanPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPeminjamanPage> createState() => _RiwayatPeminjamanPageState();
}

class _RiwayatPeminjamanPageState extends State<RiwayatPeminjamanPage> {
  // Konstanta
  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color secondaryColor = const Color(0xFFD1C4E9);
  
  // Services
  final ApiService _apiService = ApiService();

  // State variables
  bool isLoading = true;
  List<dynamic> riwayatPeminjamanList = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _loadRiwayatPeminjaman();
    });
  }

  // Data loading methods
  Future<void> _loadRiwayatPeminjaman() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await _apiService.getToken();

      if (token == null) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Anda belum login. Silakan login terlebih dahulu.';
          isLoading = false;
        });
        return;
      }

      try {
        final response = await _apiService.get('peminjamans', auth: true);

        if (!mounted) return;

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            print('Response data: $data'); // Debug log
            
            List<dynamic> allPeminjaman = [];
            
            if (data is Map && data.containsKey('data')) {
              final dataContent = data['data'];
              if (dataContent is List) {
                allPeminjaman = dataContent;
              } else {
                print('Warning: data is not a List: ${dataContent.runtimeType}');
                allPeminjaman = [];
              }
            } else if (data is List) {
              allPeminjaman = data;
            }
            
            final filteredList = allPeminjaman.where((item) {
              if (item is! Map<String, dynamic>) {
                print('Warning: item is not a Map: ${item.runtimeType}');
                return false;
              }
              
              // Tampilkan semua peminjaman tanpa filter status
              return true;
              
              // Atau jika ingin tetap memfilter, tambahkan status lain:
              // final status = item['status']?.toString().toLowerCase() ?? '';
              // return status == 'returned' ||
              //        status == 'cancelled' ||
              //        status == 'rejected' ||
              //        status == 'pending' ||
              //        status == 'approved' ||
              //        status == 'borrowed';
            }).toList();

            if (!mounted) return;

            setState(() {
              riwayatPeminjamanList = filteredList;
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
          _handleErrorResponse(response);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'Terjadi kesalahan saat mengambil data: $e';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  void _handleErrorResponse(http.Response response) {
    if (!mounted) return;

    try {
      final data = jsonDecode(response.body);
      setState(() {
        errorMessage = data['message'] ?? 'Terjadi kesalahan saat memuat data';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan saat memproses respons: ${response.statusCode}';
        isLoading = false;
      });
    }
  }

  // Helper methods
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Menunggu Persetujuan';
      case 'approved': return 'Disetujui';
      case 'rejected': return 'Ditolak';
      case 'borrowed': return 'Sedang Dipinjam';
      case 'returned': return 'Dikembalikan';
      case 'cancelled': return 'Dibatalkan';
      case 'late': return 'Terlambat';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'borrowed': return Colors.green;
      case 'returned': return Colors.teal;
      case 'cancelled': return Colors.grey;
      case 'late': return Colors.deepOrange;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.pending;
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      case 'borrowed': return Icons.inventory_2;
      case 'returned': return Icons.assignment_turned_in;
      case 'cancelled': return Icons.block;
      case 'late': return Icons.warning;
      default: return Icons.help;
    }
  }

  String _getJumlahText(Map<String, dynamic> item) {
    if (item.containsKey('jumlah') && item['jumlah'] != null) {
      return item['jumlah'].toString();
    }
    
    if (item.containsKey('stok') && item['stok'] != null) {
      return item['stok'].toString();
    }
    
    return '0';
  }

  String _formatTanggal(dynamic tanggalValue) {
    if (tanggalValue == null) return '-';

    try {
      if (tanggalValue is String) {
        return DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.parse(tanggalValue));
      }

      if (tanggalValue is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(tanggalValue * 1000);
        return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
      }

      return '-';
    } catch (e) {
      print('Error formatting date: $e');
      return '-';
    }
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

  // UI building methods
  Widget _buildRiwayatList() {
    return RefreshIndicator(
      onRefresh: _loadRiwayatPeminjaman,
      color: primaryColor,
      child: riwayatPeminjamanList.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: riwayatPeminjamanList.length,
              itemBuilder: (context, index) {
                final item = riwayatPeminjamanList[index];
                final status = item['status'] ?? 'pending';
                
                // Safely get barang data
                Map<String, dynamic> barang = {};
                if (item['barang'] != null && item['barang'] is Map) {
                  barang = Map<String, dynamic>.from(item['barang']);
                }
                
                // Format dates safely
                String tanggalPinjam = _formatTanggal(item['tanggal_pinjam']);
                String tanggalKembali = _formatTanggal(item['tanggal_kembali']);
                String tanggalPengembalian = _formatTanggal(item['tanggal_pengembalian']);

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
                      if (barang.isNotEmpty && barang['foto'] != null)
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
                                  '#${item['id']?.toString() ?? ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              barang['nama']?.toString() ?? 'Barang tidak diketahui',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Jumlah: ${_getJumlahText(item)} buah',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            
                            // Tambahkan informasi nama peminjam
                            const SizedBox(height: 5),
                            Text(
                              'Nama Peminjam: ${item['nama_peminjam']?.toString() ?? 'Tidak diketahui'}',
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
                            if (status.toLowerCase() == 'returned') ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tanggal Pengembalian',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          tanggalPengembalian,
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
                            ],
                            if (item['keperluan'] != null && item['keperluan'].toString().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Keperluan:',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item['keperluan'].toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Peminjaman',
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
            onPressed: _loadRiwayatPeminjaman,
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
                ? _buildErrorView()
                : _buildRiwayatList(),
      ),
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
              errorMessage!,
              style: GoogleFonts.poppins(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRiwayatPeminjaman,
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

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Belum ada riwayat peminjaman',
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Anda belum memiliki riwayat peminjaman barang yang selesai, dibatalkan, atau ditolak',
              style: GoogleFonts.poppins(
                fontSize: 14, 
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _loadRiwayatPeminjaman,
            icon: const Icon(Icons.refresh),
            label: Text(
              'Refresh',
              style: GoogleFonts.poppins(),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




