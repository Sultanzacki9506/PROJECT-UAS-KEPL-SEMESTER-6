import 'package:flutter/material.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController(); // kontrol input email
  final TextEditingController passwordController = TextEditingController(); // kontrol input password
  final _formKey = GlobalKey<FormState>(); // kunci validasi form
  bool _isPasswordVisible = false; // toggle buat lihat/sembunyiin password
  bool _isLoading = false; // status loading pas login

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) { // validasi form dulu
      setState(() => _isLoading = true); // mulai loading
      try {
        final token = await ApiService().login(
          emailController.text.trim(),
          passwordController.text,
        );

        // cek apakah widget masih ada sebelum setState (hindari error)
        if (!mounted) return;
        setState(() => _isLoading = false); // loading selesai

        if (token != null) {
          // Login berhasil, langsung masuk dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // Kredensial salah (email/password gak cocok)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email atau Password salah!"),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        // Gagal koneksi ke server, kasih tahu user
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal terhubung ke server. Cek koneksi."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient( // background gradasi hijau
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Header Area
            const Icon(Icons.recycling, size: 80, color: Colors.white), // logo recycle
            const SizedBox(height: 10),
            const Text(
              "BANK SAMPAH",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const Text(
              "Kelola sampah jadi berkah",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            // Login Card (putih melengkung di atas)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView( // biar bisa discroll kalo keyboard muncul
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selamat Datang",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text("Silakan login untuk melanjutkan",
                            style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 30),
                        // Field Email
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Email tidak boleh kosong" : null,
                        ),
                        const SizedBox(height: 20),
                        // Field Password
                        TextFormField(
                          controller: passwordController,
                          obscureText: !_isPasswordVisible, // sembunyiin password
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? "Password tidak boleh kosong" : null,
                        ),
                        const SizedBox(height: 40),
                        // Tombol Login
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            onPressed: _isLoading ? null : _handleLogin, // matiin tombol saat loading
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white) // spinner
                                : const Text(
                                    "MASUK",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}