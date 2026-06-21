import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ruang_nada/api_service.dart';
import 'package:ruang_nada/theme.dart';
import 'package:ruang_nada/models.dart';

class MusikFormPage extends StatefulWidget {
  final AlatMusik? alatMusik;
  const MusikFormPage({super.key, this.alatMusik});

  @override
  State<MusikFormPage> createState() => _MusikFormPageState();
}

class _MusikFormPageState extends State<MusikFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _asalDaerahController = TextEditingController();
  final _hargaController = TextEditingController();

  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _hasChanges = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  bool get _isEdit => widget.alatMusik != null;

  final List<String> _kategoriOptions = [
    'Dawai',
    'Tiup',
    'Perkusi',
    'Keyboard',
    'Elektronik',
    'Lainnya',
  ];

  // Step tracking: 0=Info, 1=Foto, 2=Simpan
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final alat = widget.alatMusik!;
      _namaController.text = alat.namaAlat;
      _kategoriController.text = alat.kategori;
      _deskripsiController.text = alat.deskripsi;
      _asalDaerahController.text = alat.asalDaerah;
      _hargaController.text = alat.harga.toString();
    }
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    // Track changes
    for (final c in [
      _namaController,
      _kategoriController,
      _deskripsiController,
      _asalDaerahController,
      _hargaController
    ]) {
      c.addListener(_markChanged);
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _namaController.dispose();
    _kategoriController.dispose();
    _deskripsiController.dispose();
    _asalDaerahController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges && _image == null) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.warning, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text("Buang perubahan?", style: AppTheme.headingSm),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Perubahan yang belum disimpan akan hilang. Yakin ingin keluar?",
                style: AppTheme.bodySm,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(
                            color: AppTheme.sand, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Tetap di sini",
                          style: GoogleFonts.inter(
                            color: AppTheme.textMid,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Keluar",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.sand,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Pilih Sumber Gambar", style: AppTheme.headingSm),
            const SizedBox(height: 20),
            _SourceOption(
              icon: Icons.camera_alt_rounded,
              label: "Kamera",
              subtitle: "Ambil foto baru",
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 10),
            _SourceOption(
              icon: Icons.photo_library_rounded,
              label: "Galeri",
              subtitle: "Pilih dari galeri",
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() {
          _image = File(picked.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal ambil gambar: $e', isError: true);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }

    double? harga;
    try {
      harga = double.parse(_hargaController.text.trim());
    } catch (_) {
      _showSnack('Harga harus berupa angka', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
      _currentStep = 2;
    });

    try {
      final success = await ApiService().saveAlatMusik(
        namaAlat: _namaController.text.trim(),
        kategori: _kategoriController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        asalDaerah: _asalDaerahController.text.trim(),
        harga: harga,
        image: _image,
        id: widget.alatMusik?.id,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Navigator.pop(context, true);
        _showSnack('Data berhasil disimpan');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Gagal menyimpan: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: AppTheme.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges && _image == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStepIndicator(),
                    const SizedBox(height: 20),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildPhotoCard(),
                    const SizedBox(height: 28),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primary,
      foregroundColor: AppTheme.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 16),
        ),
        onPressed: () async {
          if (_hasChanges || _image != null) {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) Navigator.pop(context);
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? 'Edit Alat Musik' : 'Tambah Alat Musik',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.white,
            ),
          ),
          Text(
            _isEdit ? 'Perbarui informasi alat' : 'Isi detail alat musik baru',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Info', 'Foto', 'Simpan'];
    return Row(
      children: List.generate(steps.length, (i) {
        final isActive = i <= _currentStep;
        final isCurrent = i == _currentStep;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (i < _currentStep) setState(() => _currentStep = i);
            },
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: AnimatedContainer(
                          duration: AppTheme.durationNormal,
                          height: 2,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.sand,
                        ),
                      ),
                    AnimatedContainer(
                      duration: AppTheme.durationNormal,
                      width: isCurrent ? 28 : 24,
                      height: isCurrent ? 28 : 24,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.sand,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isActive && i < _currentStep
                            ? const Icon(Icons.check_rounded,
                                color: AppTheme.white, size: 14)
                            : Text(
                                "${i + 1}",
                                style: GoogleFonts.inter(
                                  color: isActive
                                      ? AppTheme.white
                                      : AppTheme.textMid,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: AnimatedContainer(
                          duration: AppTheme.durationNormal,
                          height: 2,
                          color: i < _currentStep
                              ? AppTheme.primary
                              : AppTheme.sand,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? AppTheme.textDark
                        : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: AppTheme.primaryLight, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Informasi Alat Musik',
                      style: AppTheme.labelMd),
                  Text('Lengkapi data di bawah',
                      style: AppTheme.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.sand, height: 1),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Nama Alat',
            controller: _namaController,
            hint: 'Contoh: Gitar Akustik',
            icon: Icons.graphic_eq_rounded,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Nama harus diisi' : null,
            onChanged: (_) {
              if (_currentStep < 1) setState(() => _currentStep = 0);
            },
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Kategori',
            controller: _kategoriController,
            items: _kategoriOptions,
            hint: 'Pilih kategori',
            icon: Icons.category_rounded,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Pilih kategori' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Asal Daerah',
            controller: _asalDaerahController,
            hint: 'Contoh: Jawa Barat',
            icon: Icons.place_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Harga (Rp)',
            controller: _hargaController,
            hint: 'Masukkan angka',
            icon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Harga harus diisi';
              if (double.tryParse(v) == null) return 'Masukkan angka valid';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Deskripsi',
            controller: _deskripsiController,
            hint: 'Ceritakan tentang alat musik ini...',
            icon: Icons.description_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelSm),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
          textCapitalization: TextCapitalization.words,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppTheme.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 10),
              child: Icon(icon, size: 18, color: AppTheme.textMid),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: AppTheme.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppTheme.textLight, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppTheme.primaryLight, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppTheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppTheme.error, width: 2),
            ),
            errorStyle: GoogleFonts.inter(
              color: AppTheme.error,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required TextEditingController controller,
    required List<String> items,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelSm),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: controller.text.isNotEmpty ? controller.text : null,
          hint: Text(hint,
              style: GoogleFonts.inter(
                  color: AppTheme.textLight, fontSize: 14)),
          icon:
              const Icon(Icons.arrow_drop_down, color: AppTheme.textMid),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 10),
              child: Icon(icon, size: 18, color: AppTheme.textMid),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: AppTheme.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppTheme.textLight, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppTheme.primaryLight, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppTheme.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              borderSide:
                  const BorderSide(color: AppTheme.error, width: 2),
            ),
            errorStyle: GoogleFonts.inter(
              color: AppTheme.error,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              controller.text = value ?? '';
              _hasChanges = true;
            });
          },
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPhotoCard() {
    final hasExistingPhoto = _isEdit &&
        widget.alatMusik!.gambarUrl != null &&
        widget.alatMusik!.gambarUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        _pickImage();
        setState(() => _currentStep = 1);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: AppTheme.primaryLight, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Foto Alat', style: AppTheme.labelMd),
                      Text('Opsional · Kamera / Galeri',
                          style: AppTheme.caption),
                    ],
                  ),
                ),
                if (_image != null)
                  GestureDetector(
                    onTap: () => setState(() => _image = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Hapus',
                        style: GoogleFonts.inter(
                          color: AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.sand, height: 1),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: AppTheme.durationNormal,
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _image != null
                    ? Colors.transparent
                    : AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: _image != null
                      ? Colors.transparent
                      : AppTheme.sand,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusM - 2),
                child: _image != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_image!, fit: BoxFit.cover),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black
                                        .withValues(alpha: 0.55),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ganti foto',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : hasExistingPhoto
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                widget.alatMusik!.gambarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) =>
                                    _emptyPhotoPlaceholder(),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin:
                                          Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withValues(
                                            alpha: 0.55),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          Icons.edit_rounded,
                                          color: Colors.white,
                                          size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Ganti foto',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _emptyPhotoPlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: AppTheme.primaryLight, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          'Ketuk untuk pilih foto',
          style: GoogleFonts.inter(
            color: AppTheme.textMid,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG · Kamera atau Galeri',
          style: AppTheme.caption,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedOpacity(
          opacity: _isSaving ? 0.75 : 1.0,
          duration: AppTheme.durationFast,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: _isSaving
                  ? const LinearGradient(
                      colors: [Color(0xFFBDBDBD), Color(0xFFBDBDBD)])
                  : AppTheme.buttonGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              boxShadow: _isSaving ? [] : AppTheme.buttonShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving ? null : _submit,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusL),
                splashColor:
                    Colors.white.withValues(alpha: 0.15),
                child: Center(
                  child: _isSaving
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
                              _isEdit
                                  ? Icons.save_outlined
                                  : Icons
                                      .add_circle_outline_rounded,
                              color: AppTheme.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isEdit
                                  ? 'Simpan Perubahan'
                                  : 'Tambah Data',
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
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (_hasChanges || _image != null) {
                    final shouldPop = await _onWillPop();
                    if (shouldPop && mounted) Navigator.pop(context);
                  } else {
                    Navigator.pop(context);
                  }
                },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusL)),
          ),
          child: Text(
            'Batal',
            style: GoogleFonts.inter(
              color: AppTheme.textMid,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SOURCE OPTION TILE
// ─────────────────────────────────────────────
class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.sand, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryLight, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.labelMd),
                  Text(subtitle, style: AppTheme.caption),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}