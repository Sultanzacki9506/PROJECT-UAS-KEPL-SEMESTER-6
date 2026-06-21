import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ruang_nada/api_service.dart';
import 'package:ruang_nada/theme.dart';

class FaceLoginPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const FaceLoginPage({super.key, required this.cameras});

  @override
  State<FaceLoginPage> createState() => _FaceLoginPageState();
}

class _FaceLoginPageState extends State<FaceLoginPage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isDetecting = false;
  String? _recognizedName;
  double? _confidence;
  bool _autoLoginScheduled = false;

  int _countdown = 3;
  Timer? _countdownTimer;
  int _cameraIndex = 0;

  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    if (widget.cameras.isNotEmpty) {
      int frontIndex = widget.cameras
          .indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _cameraIndex = frontIndex >= 0 ? frontIndex : 0;
      _initCamera();
    }
  }

  void _initCamera() {
    if (widget.cameras.isEmpty) return;
    _cameraController = CameraController(
      widget.cameras[_cameraIndex],
      ResolutionPreset.medium,
    );
    _cameraController!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _switchCamera() async {
    if (widget.cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % widget.cameras.length;
    _isDetecting = false;
    await _cameraController?.dispose();
    _cameraController = null;
    setState(() {});
    _initCamera();
  }

  Future<void> _takePictureAndDetect() async {
    if (_isDetecting || _autoLoginScheduled) return;
    setState(() {
      _isDetecting = true;
      _recognizedName = null;
      _confidence = null;
    });

    try {
      final XFile? file = await _cameraController?.takePicture();
      if (file == null) {
        setState(() => _isDetecting = false);
        return;
      }
      final result =
          await ApiService().recognizeFaceWithConfidence(File(file.path));
      if (!mounted) return;

      setState(() {
        if (result != null) {
          _recognizedName = result['label'];
          _confidence = result['confidence'];
        } else {
          _recognizedName = "Unknown";
          _confidence = null;
        }
      });

      if (_recognizedName != null &&
          _recognizedName != "Unknown" &&
          (_confidence ?? 0) >= 0.4) {
        _startAutoLoginCountdown();
      }
    } catch (e) {
      if (mounted) _showSnack("Terjadi kesalahan saat memindai wajah");
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  void _startAutoLoginCountdown() {
    _autoLoginScheduled = true;
    _countdown = 3;
    setState(() {});
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        if (_recognizedName != null && _recognizedName != "Unknown") {
          _autoLogin(_recognizedName!);
        } else {
          setState(() => _autoLoginScheduled = false);
        }
      }
    });
  }

  void _autoLogin(String name) async {
    String email = '';
    String password = '';
    final normalized = name.toLowerCase();

    switch (normalized) {
      case 'archie':
        email = 'archie@gmail.com';
        password = '123456';
        break;
      case 'sultan':
        email = 'sultan@gmail.com';
        password = '123456';
        break;
      case 'fionalita':
        email = 'fionalita@gmail.com';
        password = '123456';
        break;
      default:
        email = 'admin@gmail.com';
        password = '123456';
        break;
    }

    try {
      final token = await ApiService().login(email, password);
      if (!mounted) return;
      if (token != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showSnack("Login gagal – kredensial tidak valid");
        setState(() => _autoLoginScheduled = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error koneksi ke server");
      setState(() => _autoLoginScheduled = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _glowCtrl.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                  color: AppTheme.white, strokeWidth: 2),
              const SizedBox(height: 16),
              Text("Memuat kamera...",
                  style: GoogleFonts.inter(
                      color: AppTheme.white.withValues(alpha: 0.7),
                      fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview with correct aspect ratio
          Positioned.fill(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1 / _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),

          // Face guide overlay
          Center(child: _buildFaceGuide()),

          // Status labels
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),

          // Top bar with glass buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GlassButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () {
                    _countdownTimer?.cancel();
                    Navigator.pop(context);
                  },
                ),
                Text(
                  "Face Login",
                  style: GoogleFonts.inter(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                widget.cameras.length > 1
                    ? _GlassButton(
                        icon: Icons.flip_camera_ios_rounded,
                        onTap: _switchCamera,
                      )
                    : const SizedBox(width: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceGuide() {
    Color borderColor;
    if (_recognizedName != null && _recognizedName != "Unknown") {
      borderColor = AppTheme.success;
    } else if (_recognizedName == "Unknown") {
      borderColor = AppTheme.error;
    } else {
      borderColor = AppTheme.white.withValues(alpha: 0.5);
    }

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          width: 240,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(120),
            border: Border.all(
              color: borderColor.withValues(
                  alpha: _recognizedName == null ? _glowAnim.value : 0.9),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomPanel() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status badge
              if (_recognizedName != null &&
                  _recognizedName != "Unknown")
                _StatusBadge(
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.success,
                  text:
                      "$_recognizedName (${(_confidence != null ? (_confidence! * 100).toStringAsFixed(1) : '??')}%)",
                ),
              if (_recognizedName == "Unknown")
                const _StatusBadge(
                  icon: Icons.cancel_rounded,
                  color: AppTheme.error,
                  text: "Wajah tidak dikenali",
                ),
              if (_recognizedName == null && !_isDetecting)
                _StatusBadge(
                  icon: Icons.face_retouching_natural,
                  color: AppTheme.white.withValues(alpha: 0.8),
                  text: "Posisikan wajah dalam bingkai",
                  isSubtle: true,
                ),

              if (_autoLoginScheduled) ...[
                const SizedBox(height: 12),
                Text(
                  "Login otomatis dalam $_countdown detik...",
                  style: GoogleFonts.inter(
                    color: AppTheme.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Scan button
              if (!_autoLoginScheduled)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _isDetecting
                          ? null
                          : AppTheme.buttonGradient,
                      color: _isDetecting
                          ? AppTheme.white.withValues(alpha: 0.15)
                          : null,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusL),
                      boxShadow:
                          _isDetecting ? [] : AppTheme.buttonShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusL),
                        onTap:
                            _isDetecting ? null : _takePictureAndDetect,
                        child: Center(
                          child: _isDetecting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _recognizedName == "Unknown"
                                          ? Icons.refresh_rounded
                                          : Icons.center_focus_strong_rounded,
                                      color: AppTheme.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _recognizedName == "Unknown"
                                          ? "Coba Lagi"
                                          : "Pindai Wajah",
                                      style: GoogleFonts.inter(
                                        color: AppTheme.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  GLASS BUTTON
// ─────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  STATUS BADGE
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool isSubtle;

  const _StatusBadge({
    required this.icon,
    required this.color,
    required this.text,
    this.isSubtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSubtle
            ? Colors.white.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isSubtle
              ? Colors.white.withValues(alpha: 0.15)
              : color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: isSubtle
                    ? Colors.white.withValues(alpha: 0.8)
                    : color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ANIMATED BUILDER HELPER
// ─────────────────────────────────────────────
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(animation: animation, builder: builder);
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}