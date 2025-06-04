import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../services/api_service.dart';
import 'pengembalian_form_page.dart';

class PengembalianPage extends StatefulWidget {
  const PengembalianPage({Key? key}) : super(key: key);

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> {
  // Konstanta
  final Color primaryColor = const Color(0xFF6A1B9A);
  final Color secondaryColor = const Color(0xFFD1C4E9);
  
  // Services
  final ApiService _apiService = ApiService();

  // State variables
  bool isLoading = true;
  List<dynamic> peminjamanList = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _loadPeminjamanAktif();
    });
  }

  // Data loading methods
  Future<void> _loadPeminjamanAktif() async {
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
        // Gunakan endpoint peminjaman untuk mendapatkan daftar peminjaman aktif
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
            
            // Filter peminjaman yang dapat dikembalikan (status apapun selain 'returned' atau 'dikembalikan')
            final filteredList = allPeminjaman.where((item) {
              if (item is! Map<String, dynamic>) {
                print('Warning: item is not a Map: ${item.runtimeType}');
                return false;
              }
              
              final status = item['status']?.toString().toLowerCase() ?? '';
              // Tampilkan semua peminjaman kecuali yang sudah dikembalikan
              return !status.contains('return') && !status.contains('kembali');
            }).toList();

            if (!mounted) return;

            setState(() {
              peminjamanList = filteredList;
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

  void _handleErrorResponse(dynamic response) {
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

  String _getItemId(Map<String, dynamic> item) {
    if (item.containsKey('id')) {
      if (item['id'] is int) return item['id'].toString();
      if (item['id'] is String) return item['id'];
    }
    return '';
  }

  int? safeParseInt(dynamic value) {
    if (value == null) return null;
    
    if (value is int) return value;
    
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Error parsing int from string: $e');
        return null;
      }
    }
    
    return null;
  }

  String _getJumlahText(Map<String, dynamic> item) {
    // Coba ambil jumlah dan konversi dengan aman
    if (item.containsKey('jumlah')) {
      final jumlah = safeParseInt(item['jumlah']);
      if (jumlah != null) return jumlah.toString();
    }
    
    // Coba ambil stok dan konversi dengan aman
    if (item.containsKey('stok')) {
      final stok = safeParseInt(item['stok']);
      if (stok != null) return stok.toString();
    }
    
    return '1';
  }

  // UI building methods
  Widget _buildPeminjamanList() {
    return RefreshIndicator(
      onRefresh: _loadPeminjamanAktif,
      color: primaryColor,
      child: peminjamanList.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: peminjamanList.length,
              itemBuilder: (context, index) {
                // Pastikan item adalah Map
                if (index >= peminjamanList.length) {
                  return const SizedBox.shrink();
                }
                
                final item = peminjamanList[index];
                if (item == null || item is! Map<String, dynamic>) {
                  print('Invalid item at index $index: $item');
                  return const SizedBox.shrink();
                }
                
                // Safely get barang data
                Map<String, dynamic> barang = {};
                if (item['barang'] != null) {
                  if (item['barang'] is Map) {
                    barang = Map<String, dynamic>.from(item['barang'] as Map);
                  } else {
                    print('Unexpected barang type: ${item['barang'].runtimeType}');
                  }
                }
                
                // Format dates safely
                String tanggalPinjam = _formatTanggal(item['tanggal_pinjam']);
                String tanggalKembali = _formatTanggal(item['tanggal_kembali']);
                
                // Get item ID for pengembalian
                final peminjamanId = safeParseInt(item['id']) ?? 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.inventory_2,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Sedang Dipinjam',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '#${_getItemId(item)}',
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
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Dapatkan ID dengan aman
                              final peminjamanId = item['id'];
                              print('Membuka form pengembalian untuk ID: $peminjamanId (tipe: ${peminjamanId.runtimeType})');
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PengembalianFormPage(peminjamanId: peminjamanId),
                                ),
                              ).then((_) {
                                // Refresh data setelah kembali dari form pengembalian
                                _loadPeminjamanAktif();
                              });
                            },
                            icon: const Icon(Icons.assignment_return),
                            label: Text(
                              'Ajukan Pengembalian',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
          'Pengembalian Barang',
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
            onPressed: _loadPeminjamanAktif,
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
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : errorMessage != null
                ? _buildErrorView()
                : _buildPeminjamanList(),
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
              onPressed: _loadPeminjamanAktif,
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
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Tidak ada barang yang dipinjam',
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
              'Anda tidak memiliki barang yang sedang dipinjam saat ini',
              style: GoogleFonts.poppins(
                fontSize: 14, 
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _loadPeminjamanAktif,
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


