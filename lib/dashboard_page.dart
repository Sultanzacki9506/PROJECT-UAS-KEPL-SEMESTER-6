import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ruang_nada/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruang_nada/api_service.dart';
import 'package:ruang_nada/musik_form_page.dart';
import 'package:ruang_nada/theme.dart';
import 'package:ruang_nada/models.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  List<AlatMusik> allAlat = [];
  List<AlatMusik> filteredAlat = [];
  TextEditingController searchController = TextEditingController();
  bool _isLoading = true;

  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    refreshData();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: AppTheme.durationSlow,
    );
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOutBack);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _fabCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    searchController.dispose();
    super.dispose();
  }

  void refreshData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().fetchAlatMusik();
      if (!mounted) return;
      setState(() {
        allAlat = data;
        filteredAlat = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack("Gagal memuat data: $e", isError: true);
    }
  }

  void filterData(String query) {
    setState(() {
      filteredAlat = allAlat
          .where((item) =>
              item.namaAlat.toLowerCase().contains(query.toLowerCase()) ||
              item.kategori.toLowerCase().contains(query.toLowerCase()) ||
              item.asalDaerah.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
            borderRadius: BorderRadius.circular(AppTheme.radiusM)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumDialog(
        title: "Keluar Aplikasi",
        body: "Apakah kamu yakin ingin keluar dari sesi ini?",
        confirm: "Keluar",
        cancel: "Batal",
        isDanger: true,
        onConfirm: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          if (ctx.mounted) {
            Navigator.pushNamedAndRemoveUntil(ctx, '/', (route) => false);
          }
        },
      ),
    );
  }

  void _confirmDelete(int id, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumDialog(
        title: "Hapus Data",
        body: "Yakin hapus data '$nama'? Tindakan ini tidak bisa dibatalkan.",
        confirm: "Hapus",
        cancel: "Batal",
        isDanger: true,
        onConfirm: () async {
          Navigator.pop(ctx);
          try {
            await ApiService().deleteAlatMusik(id);
            if (!mounted) return;
            refreshData();
            _showSnack("Data berhasil dihapus");
          } catch (e) {
            if (!mounted) return;
            _showSnack("Gagal menghapus: $e", isError: true);
          }
        },
      ),
    );
  }

  void _showDetailSheet(AlatMusik alat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DetailBottomSheet(
        alat: alat,
        onEdit: () {
          Navigator.pop(ctx);
          _navigateToForm(alat);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDelete(alat.id!, alat.namaAlat);
        },
      ),
    );
  }

  void _navigateToForm([AlatMusik? alat]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusikFormPage(alatMusik: alat),
      ),
    );
    if (result == true) refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) =>
            [_buildSliverAppBar()],
        body: RefreshIndicator(
          onRefresh: () async => refreshData(),
          color: AppTheme.primary,
          child: Column(
            children: [
              _buildSearchBar(),
              _buildStats(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _SmallFab(
              icon: Icons.chat_bubble_outline_rounded,
              color: AppTheme.info,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.buttonGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _navigateToForm(),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.add_rounded,
                      color: AppTheme.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ─────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
        title: Text(
          "Ruang Nada",
          style: GoogleFonts.inter(
            color: AppTheme.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration:
                  const BoxDecoration(gradient: AppTheme.heroGradient),
            ),
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.logout_rounded,
                color: Colors.white70, size: 18),
          ),
          onPressed: () => _confirmLogout(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.cardShadow,
        ),
        child: TextField(
          controller: searchController,
          onChanged: filterData,
          style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: "Cari nama, kategori, atau daerah...",
            hintStyle: GoogleFonts.inter(
                color: AppTheme.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w400),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppTheme.textLight, size: 20),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textLight, size: 18),
                    onPressed: () {
                      searchController.clear();
                      filterData('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final uniqueKategori =
        allAlat.map((a) => a.kategori).toSet().length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Text(
            _isLoading
                ? "Memuat data..."
                : "${filteredAlat.length} alat musik",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMid,
              letterSpacing: 0.3,
            ),
          ),
          if (!_isLoading && uniqueKategori > 0) ...[
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.textLight,
              ),
            ),
            Text(
              "$uniqueKategori kategori",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textLight,
              ),
            ),
          ],
          const Spacer(),
          if (!_isLoading && allAlat.isNotEmpty)
            GestureDetector(
              onTap: refreshData,
              child: Row(
                children: [
                  const Icon(Icons.refresh_rounded,
                      size: 14, color: AppTheme.primaryLight),
                  const SizedBox(width: 4),
                  Text(
                    "Refresh",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return _buildShimmerList();
    }

    if (filteredAlat.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.buttonGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.music_off_rounded,
                  size: 38, color: AppTheme.white),
            ),
            const SizedBox(height: 20),
            Text("Belum ada data alat musik",
                style: AppTheme.headingSm),
            const SizedBox(height: 6),
            Text(
              "Ketuk tombol + untuk menambahkan data",
              style: AppTheme.bodySm,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: filteredAlat.length,
      itemBuilder: (context, index) {
        final alat = filteredAlat[index];
        return _AlatMusikCard(
          alat: alat,
          index: index,
          onTap: () => _showDetailSheet(alat),
          onEdit: () => _navigateToForm(alat),
          onDelete: () => _confirmDelete(alat.id!, alat.namaAlat),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppTheme.shimmerBase,
      highlightColor: AppTheme.shimmerHighlight,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 140, height: 14, color: AppTheme.white),
                      const SizedBox(height: 8),
                      Container(
                          width: 90, height: 10, color: AppTheme.white),
                      const SizedBox(height: 6),
                      Container(
                          width: 60, height: 10, color: AppTheme.white),
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
}

// ─────────────────────────────────────────────
//  ALAT MUSIK CARD
// ─────────────────────────────────────────────
class _AlatMusikCard extends StatelessWidget {
  final AlatMusik alat;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlatMusikCard({
    required this.alat,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            onTap: onTap,
            splashColor: AppTheme.primaryLight.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (alat.gambarUrl != null &&
                            alat.gambarUrl!.isNotEmpty)
                        ? Image.network(
                            alat.gambarUrl!,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                _iconPlaceholder(),
                          )
                        : _iconPlaceholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alat.namaAlat,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                alat.kategori,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Rp ${_formatPrice(alat.harga)}",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.goldDark,
                              ),
                            ),
                          ],
                        ),
                        if (alat.asalDaerah.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            alat.asalDaerah,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textMid,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _ActionBtn(
                    icon: Icons.edit_outlined,
                    color: AppTheme.info,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 4),
                  _ActionBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppTheme.error,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return "${(price / 1000000).toStringAsFixed(1)}jt";
    } else if (price >= 1000) {
      return "${(price / 1000).toStringAsFixed(0)}rb";
    }
    return price.toStringAsFixed(0);
  }

  Widget _iconPlaceholder() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: AppTheme.buttonGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.music_note_rounded,
          color: AppTheme.white, size: 26),
    );
  }
}

// ─────────────────────────────────────────────
//  DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────
class _DetailBottomSheet extends StatelessWidget {
  final AlatMusik alat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailBottomSheet({
    required this.alat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
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

              // Image
              if (alat.gambarUrl != null && alat.gambarUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  child: Image.network(
                    alat.gambarUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: AppTheme.buttonGradient,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusL),
                      ),
                      child: const Icon(Icons.music_note_rounded,
                          color: AppTheme.white, size: 60),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Name & Category
              Text(alat.namaAlat,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(alat.kategori,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryLight,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Rp ${alat.harga.toStringAsFixed(0)}",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.goldDark,
                    ),
                  ),
                ],
              ),
              if (alat.asalDaerah.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        size: 16, color: AppTheme.textMid),
                    const SizedBox(width: 6),
                    Text(alat.asalDaerah,
                        style: AppTheme.bodySm),
                  ],
                ),
              ],
              if (alat.deskripsi.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: AppTheme.sand),
                const SizedBox(height: 12),
                Text("Deskripsi", style: AppTheme.labelSm),
                const SizedBox(height: 6),
                Text(alat.deskripsi, style: AppTheme.bodyLg),
              ],
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon:
                          const Icon(Icons.edit_outlined, size: 18),
                      label: Text("Edit",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.info,
                        side: const BorderSide(
                            color: AppTheme.info, width: 1.5),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      onPressed: onEdit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18),
                      label: Text("Hapus",
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: AppTheme.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _SmallFab extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _SmallFab({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.glowShadow(color),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PREMIUM DIALOG
// ─────────────────────────────────────────────
class _PremiumDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirm;
  final String cancel;
  final bool isDanger;
  final VoidCallback onConfirm;

  const _PremiumDialog({
    required this.title,
    required this.body,
    required this.confirm,
    required this.cancel,
    required this.isDanger,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      elevation: 0,
      backgroundColor: AppTheme.white,
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
                    color: (isDanger ? AppTheme.error : AppTheme.success)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDanger
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color:
                        isDanger ? AppTheme.error : AppTheme.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(title, style: AppTheme.headingSm),
              ],
            ),
            const SizedBox(height: 16),
            Text(body, style: AppTheme.bodySm),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(
                          color: AppTheme.sand, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      cancel,
                      style: GoogleFonts.inter(
                        color: AppTheme.textMid,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDanger
                          ? AppTheme.error
                          : AppTheme.success,
                      foregroundColor: AppTheme.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      confirm,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}