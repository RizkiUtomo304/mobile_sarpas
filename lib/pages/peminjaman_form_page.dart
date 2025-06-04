import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sisfo_sarpas/models/peminjaman.dart';
import 'package:sisfo_sarpas/services/peminjaman_service.dart';

class PeminjamanFormPage extends StatefulWidget {
  final int barangId;
  final String barangNama;
  final int stokTersedia;

  const PeminjamanFormPage({
    Key? key,
    required this.barangId,
    required this.barangNama,
    required this.stokTersedia,
  }) : super(key: key);

  @override
  State<PeminjamanFormPage> createState() => _PeminjamanFormPageState();
}

class _PeminjamanFormPageState extends State<PeminjamanFormPage> {
  final _formKey = GlobalKey<FormState>();
  final PeminjamanService _peminjamanService = PeminjamanService();

  // Warna tema
  final Color primaryColor = const Color(0xFF6A1B9A); // Ungu tua
  final Color secondaryColor = const Color(0xFFD1C4E9); // Ungu muda

  // Form fields
  String _namaPeminjam = '';
  DateTime _tanggalPinjam = DateTime.now();
  DateTime _tanggalKembali = DateTime.now().add(const Duration(days: 7)); // Default 7 days after borrow date
  String _keperluan = '';
  int _stok = 1;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('username');

      if (savedUsername != null && mounted) {
        setState(() {
          _namaPeminjam = savedUsername;
        });
      }
    } catch (e) {
      // Handle error
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Form Peminjaman',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info barang
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
                    'Informasi Barang',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Nama Barang', widget.barangNama),
                  _buildInfoRow('Stok Tersedia', '${widget.stokTersedia} unit'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Form peminjaman
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
                    'Detail Peminjaman',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nama Peminjam
                  _buildTextField(
                    label: 'Nama Peminjam',
                    value: _namaPeminjam,
                    onChanged: (value) {
                      setState(() {
                        _namaPeminjam = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama peminjam tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tanggal Pinjam
                  _buildDateField(
                    label: 'Tanggal Pinjam',
                    value: _tanggalPinjam,
                    onChanged: (date) {
                      if (date != null) {
                        setState(() {
                          _tanggalPinjam = date;
                          // Update tanggal kembali to be 7 days after new tanggal pinjam
                          _tanggalKembali = date.add(const Duration(days: 7));
                        });
                      }
                    },
                    firstDate: DateTime.now().subtract(const Duration(days: 30)), // Memungkinkan pemilihan tanggal 30 hari ke belakang
                    lastDate: DateTime.now().add(const Duration(days: 90)), // Memperpanjang rentang hingga 90 hari ke depan
                  ),
                  const SizedBox(height: 16),

                  // Tanggal Kembali
                  _buildDateField(
                    label: 'Tanggal Kembali',
                    value: _tanggalKembali,
                    onChanged: (date) {
                      if (date != null) {
                        setState(() {
                          _tanggalKembali = date;
                        });
                      }
                    },
                    firstDate: DateTime.now().subtract(const Duration(days: 30)), // Memungkinkan pemilihan tanggal 30 hari ke belakang
                    lastDate: DateTime.now().add(const Duration(days: 180)), // Memperpanjang rentang hingga 180 hari ke depan
                    helperText: 'Tanggal pengembalian barang',
                  ),
                  const SizedBox(height: 16),

                  // Keperluan
                  _buildTextField(
                    label: 'Keperluan',
                    value: _keperluan,
                    onChanged: (value) {
                      setState(() {
                        _keperluan = value;
                      });
                    },
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Keperluan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Jumlah
                  _buildNumberField(
                    label: 'Jumlah',
                    value: _stok,
                    onChanged: (value) {
                      setState(() {
                        _stok = value;
                      });
                    },
                    min: 1,
                    max: widget.stokTersedia,
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
          _buildSubmitButton(),
        ],
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

  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          style: GoogleFonts.poppins(),
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime value,
    required Function(DateTime?) onChanged,
    required DateTime firstDate,
    required DateTime lastDate,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: firstDate,
              lastDate: lastDate,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            onChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMMM yyyy', 'id_ID').format(value),
                  style: GoogleFonts.poppins(),
                ),
                Icon(Icons.calendar_today, color: primaryColor),
              ],
            ),
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              helperText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required Function(int) onChanged,
    required int min,
    required int max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min
                  ? () => onChanged(value - 1)
                  : null,
              color: primaryColor,
            ),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max
                  ? () => onChanged(value + 1)
                  : null,
              color: primaryColor,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            'Maksimal: $max',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: Text(
          'Ajukan Peminjaman',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        // Gunakan PeminjamanService untuk membuat peminjaman
        final result = await _peminjamanService.createPeminjaman(
          namaPeminjam: _namaPeminjam,
          barangId: widget.barangId,
          tanggalPinjam: _tanggalPinjam,
          tanggalKembali: _tanggalKembali,
          stok: _stok,
          keperluan: _keperluan,
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          // Peminjaman berhasil
          Navigator.pop(context, true); // Kembali dengan status sukses
        } else {
          // Peminjaman gagal
          setState(() {
            _errorMessage = result['message']?.toString() ?? 'Terjadi kesalahan';
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
