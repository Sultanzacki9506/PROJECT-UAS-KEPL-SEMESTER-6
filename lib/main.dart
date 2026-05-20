import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'dashboard_page.dart';

Future<void> main() async {
  // pastikan Flutter udah siap sebelum jalanin apa pun
  WidgetsFlutterBinding.ensureInitialized();

  // ambil token dari hp, buat ngecek apakah user pernah login sebelumnya
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  // jalankan aplikasi sambil bawa info login (biar gak login ulang kalau token masih ada)
  runApp(BankSampahApp(isLoggedIn: token != null));
}

class BankSampahApp extends StatelessWidget {
  const BankSampahApp({super.key, required this.isLoggedIn});

  final bool isLoggedIn; // status login

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bank Sampah Sungailiat',
      debugShowCheckedModeBanner: false, // matiin pita debug
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), // tema warna hijau
        useMaterial3: true,
      ),
      // kalau sudah login, langsung masuk dashboard; kalau belum, ke login
      initialRoute: isLoggedIn ? '/dashboard' : '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}