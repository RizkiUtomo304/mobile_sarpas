import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sisfo_sarpas/services/pengembalian_service.dart';

class PengembalianFormPage extends StatefulWidget {
  final String peminjamanId;
  final String namaBarang;
  final int jumlahPinjam;
  final DateTime tanggalPinjam;

  const PengembalianFormPage({
    Key? key,
    required this.peminjamanId,
    required this.namaBarang,
    required this.jumlahPinjam,
    required this.tanggalPinjam,
  }) : super(key: key);

  @override
  State<PengembalianFormPage> createState() => _PengembalianFormPageState();
}

class _PengembalianFormPageState extends State<PengembalianFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaPengembaliController = TextEditingController();
  final _jumlahKembaliController = TextEditingController();
  final _catatanController = TextEditingController();
  
  DateTime _tglKembali = DateTime.now();
  String _kondisi = 'Baik';
  bool _isLoading = false;
  String? _errorMessage;
  
  final PengembalianService _pengembalianService = PengembalianService();
  
  @override
  void initState() {
    super.initState();
    _jumlahKembaliController.text = widget.jumlahPinjam.toString();
  }
  
  @override
  void dispose() {
    _namaPengembaliController.dispose();
    _jumlahKembaliController.dispose();
    _catatanController.dispose();
    super.dispose();
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
        backgroundColor: const Color(0xFF6A1B9A), // Primary color from your app
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Barang
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Peminjaman',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Nama Barang', widget.namaBarang),
                    _buildInfoRow('Jumlah Pinjam', widget.jumlahPinjam.toString()),
                    _buildInfoRow(
                      'Tanggal Pinjam',
                      DateFormat('dd MMMM yyyy', 'id_ID').format(widget.tanggalPinjam),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Form Pengembalian
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Form Pengembalian',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nama Pengembali
                    TextFormField(
                      controller: _namaPengembaliController,
                      decoration: InputDecoration(
                        labelText: 'Nama Pengembali',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama pengembali tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Tanggal Kembali
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _tglKembali,
                          firstDate: widget.tanggalPinjam,
                          lastDate: DateTime.now().add(const Duration(days: 1)),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_tglKembali)),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Jumlah Kembali
                    TextFormField(
                      controller: _jumlahKembaliController,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Kembali',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah kembali tidak boleh kosong';
                        }
                        final jumlah = int.tryParse(value);
                        if (jumlah == null) {
                          return 'Jumlah harus berupa angka';
                        }
                        if (jumlah <= 0) {
                          return 'Jumlah harus lebih dari 0';
                        }
                        if (jumlah > widget.jumlahPinjam) {
                          return 'Jumlah tidak boleh melebihi jumlah pinjam';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Kondisi
                    DropdownButtonFormField<String>(
                            value: _kondisi,
                            decoration: InputDecoration(
                              labelText: 'Kondisi',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Baik', child: Text('Baik')),
                              DropdownMenuItem(value: 'Rusak', child: Text('Rusak')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _kondisi = value;
                                });
                              }
                            },
                          ),

                    const SizedBox(height: 16),
                    
                    // Catatan
                    TextFormField(
                      controller: _catatanController,
                      decoration: InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(
                    color: Colors.red[700],
                    fontSize: 14,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A), // Primary color from your app
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Ajukan Pengembalian',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Tambahkan logging untuk melihat data yang dikirim
        print('Mengirim data: {' +
            'peminjamanId: ${widget.peminjamanId}, ' +
            'namaPengembali: ${_namaPengembaliController.text}, ' +
            'tanggalKembali: ${_tglKembali}, ' +
            'jumlahKembali: ${_jumlahKembaliController.text}, ' +
            'kondisi: $_kondisi, ' +
            'catatan: ${_catatanController.text}}');

        // Pastikan service sudah diinisialisasi
        if (_pengembalianService == null) {
          throw Exception('PengembalianService belum diinisialisasi');
        }

        final result = await _pengembalianService.ajukanPengembalian(
          peminjamanId: widget.peminjamanId,
          namaPengembali: _namaPengembaliController.text,
          tanggalKembali: _tglKembali,
          jumlahKembali: int.parse(_jumlahKembaliController.text),
          kondisi: _kondisi,
          catatan: _catatanController.text.isNotEmpty ? _catatanController.text : null,
        );

        // Tambahkan logging untuk melihat hasil
        print('Hasil dari API: $result');

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Perbaikan penanganan null
        if (result == null) {
          setState(() {
            _errorMessage = 'Terjadi kesalahan: Respons dari server kosong';
          });
          return;
        }

        if (result['success'] == true) {
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengembalian berhasil diajukan'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Kembali ke halaman sebelumnya
          Navigator.pop(context, true);
        } else {
          // Tampilkan pesan error
          setState(() {
            _errorMessage = result['message'] ?? 'Terjadi kesalahan pada server';
          });
        }
      } catch (e) {
        print('Error submitting form: $e');
        
        if (!mounted) return;
        
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      }
    }
  }
}
