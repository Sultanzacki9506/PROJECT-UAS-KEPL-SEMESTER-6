import 'package:flutter/material.dart';
import 'package:nodejs_flutter/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'sampah_form_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List allSampah = []; // nyimpen semua data asli dari server
  List filteredSampah = []; // data yang udah difilter (buat search)
  TextEditingController searchController = TextEditingController(); // kontrol input search
  bool _isLoading = true; // buat nunjukin loading pertama kali

  // ambil ulang data dari server
  void refreshData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService().fetchSampah(); // panggil API
      if (!mounted) return; // jangan lanjut kalo layar udah kebuang
      setState(() {
        allSampah = data;
        filteredSampah = data; // reset filter
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat data: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // filter data pas user ngetik di search bar
  void filterData(String query) {
    setState(() {
      filteredSampah = allSampah
          .where((item) =>
              item['nama_sampah'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // dialog konfirmasi logout
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Apakah yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // batal
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              // hapus token dari hp
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              if (context.mounted) {
                // balik ke login, hapus semua riwayat navigasi
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Berhasil keluar")),
                );
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // dialog hapus data sampah
  void _confirmDelete(int id, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: Text("Apakah yakin ingin menghapus data '$nama'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // batal
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // tutup dialog
              try {
                await ApiService().deleteSampah(id); // panggil API hapus
                if (!mounted) return;
                refreshData(); // refresh daftar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Data berhasil dihapus"),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Gagal menghapus: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    refreshData(); // langsung ambil data pas halaman dibuka
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Bank Sampah",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _confirmLogout(context), // tombol logout
          ),
        ],
      ),
      body: Column(
        children: [
          // search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: filterData,
              decoration: InputDecoration(
                hintText: "Cari jenis sampah...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // daftar sampah
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator()) // loading awal
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredSampah.length,
                    itemBuilder: (context, index) {
                      final item = filteredSampah[index];
                      // ambil URL gambar dari backend (udah full URL)
                      final String? picUrl = item['pic_url'];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: picUrl != null && picUrl.isNotEmpty
                                ? Image.network(
                                    picUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, error, stack) =>
                                        Container(
                                      color: Colors.green[100],
                                      width: 60,
                                      height: 60,
                                      child: const Icon(Icons.recycling,
                                          color: Colors.green),
                                    ),
                                  )
                                : Container(
                                    color: Colors.green[100],
                                    width: 60,
                                    height: 60,
                                    child: const Icon(Icons.recycling,
                                        color: Colors.green),
                                  ),
                          ),
                          title: Text(
                            item['nama_sampah'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // tombol edit
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Colors.blue),
                                onPressed: () async {
                                  bool? updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SampahFormPage(sampah: item),
                                    ),
                                  );
                                  if (updated == true) refreshData();
                                },
                              ),
                              // tombol hapus
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _confirmDelete(
                                    item['id'], item['nama_sampah'] ?? ''),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // tombol chatbot
          FloatingActionButton.small(
            heroTag: "btnChat",
            backgroundColor: Colors.blueAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatPage()),
              );
            },
            child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ),
          const SizedBox(height: 12),
          // tombol tambah sampah
          FloatingActionButton(
            heroTag: "btnAdd",
            backgroundColor: Colors.green,
            onPressed: () async {
              bool? added = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SampahFormPage()),
              );
              if (added == true) refreshData();
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}