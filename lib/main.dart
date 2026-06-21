import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ruang_nada/login_page.dart';
import 'package:ruang_nada/dashboard_page.dart';
import 'package:ruang_nada/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');
  runApp(RuangNadaApp(
    isLoggedIn: token != null,
    cameras: cameras,
  ));
}

class RuangNadaApp extends StatelessWidget {
  final bool isLoggedIn;
  final List<CameraDescription> cameras;
  const RuangNadaApp({super.key, required this.isLoggedIn, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme,
    );

    return MaterialApp(
      title: 'Ruang Nada',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          primary: AppTheme.primary,
          secondary: AppTheme.gold,
          surface: AppTheme.white,
        ),
        useMaterial3: true,
        textTheme: baseTextTheme,
        scaffoldBackgroundColor: AppTheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppTheme.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
            textStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: const BorderSide(color: AppTheme.textLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: AppTheme.textLight),
          labelStyle: GoogleFonts.inter(color: AppTheme.textMid),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          margin: const EdgeInsets.only(bottom: 10),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppTheme.primary,
          foregroundColor: AppTheme.white,
        ),
        iconTheme: const IconThemeData(color: AppTheme.textMid),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: isLoggedIn ? '/dashboard' : '/',
      routes: {
        '/': (context) => LoginPage(cameras: cameras),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}