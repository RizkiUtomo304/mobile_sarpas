import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/barang_page.dart';
import 'pages/peminjaman_form_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi format tanggal untuk bahasa Indonesia
  await initializeDateFormatting('id_ID', null);
  
  // Aktifkan widget inspector service
  // Tambahkan baris ini untuk memastikan inspector berfungsi dengan baik
  WidgetsFlutterBinding.ensureInitialized().addPostFrameCallback((_) {
    WidgetsBinding.instance.endOfFrame.then((_) {
      if (WidgetsBinding.instance.renderViewElement != null) {
        // Pastikan service inspector diaktifkan
        WidgetsBinding.instance.addPersistentFrameCallback((_) {});
      }
    });
  });
  
  // Error handling global
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log error ke konsol
    print('Flutter error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };
  
  // Tangkap error yang tidak tertangkap oleh Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Uncaught error: $error');
    print('Stack trace: $stack');
    return true;
  };
  
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  runApp(MyApp(token: token));
}

class MyApp extends StatelessWidget {
  final String? token;
  
  const MyApp({super.key, this.token});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sisfo Sarpras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6A1B9A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A1B9A),
          primary: const Color(0xFF6A1B9A),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: token != null ? const HomePage() : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/barang': (context) => const BarangPage(),
        '/peminjaman-form': (context) => PeminjamanFormPage(
          barangId: (ModalRoute.of(context)?.settings.arguments as Map)['barangId'],
          barangNama: (ModalRoute.of(context)?.settings.arguments as Map)['barangNama'],
          stokTersedia: (ModalRoute.of(context)?.settings.arguments as Map)['stokTersedia'],
        ),
      },
      // Error handling untuk widget
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Terjadi kesalahan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorDetails.exception.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        };
        if (widget != null) return widget;
        throw StateError('widget is null');
      },
    );
  }
}

