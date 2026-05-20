import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // alamat backend Node.js (ganti sesuai IP laptop kamu)
  // final String baseUrl = "http://192.168.18.2:3000";
  // // alamat chatbot Python
  // final String baseUrlNlp = "http://192.168.18.2:8000";
final String baseUrl = "http://10.0.2.2:3000";
final String baseUrlNlp = "http://10.0.2.2:8000";

  // nyimpen id sesi biar chatbot ingat obrolan sebelumnya
  String? _sessionId;

  // ==================== CHATBOT ====================
  Future<String> askChatbot(String message) async {
    try {
      // siapin data yang dikirim, session_id cuma disertakan kalau sudah ada
      final body = <String, dynamic>{'message': message};
      if (_sessionId != null) {
        body['session_id'] = _sessionId;
      }

      // kirim permintaan POST ke chatbot
      final response = await http.post(
        Uri.parse('$baseUrlNlp/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // kalau chatbot ngasih session_id baru, kita simpan biar obrolan lanjut
        _sessionId = data['session_id'] ?? _sessionId;
        return data['response'];
      } else {
        return "Maaf, server sedang sibuk.";
      }
    } catch (e) {
      // kalau gagal konek atau ada error lain, kasih tahu user
      return "Gagal terhubung ke chatbot.";
    }
  }

  // ==================== LOGIN ====================
  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        // simpan token di hp biar下次 login gak perlu isi ulang
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        return token;
      }
      // kalau status bukan 200 (misal 400), berarti kredensial salah
      return null;
    } catch (e) {
      // lempar exception biar ditangkap di halaman login
      throw Exception("Gagal login: $e");
    }
  }

  // ==================== FETCH SAMPAH ====================
  Future<List> fetchSampah() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    // kalau token gak ada, gak bisa lanjut – suruh login ulang
    if (token == null) throw Exception("Token tidak ditemukan. Silakan login ulang.");

    final response = await http.get(
      Uri.parse('$baseUrl/sampah'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // parse JSON dan kirim ke dashboard
      return jsonDecode(response.body);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // token expired atau gak valid
      throw Exception("Sesi habis. Silakan login kembali.");
    } else {
      throw Exception("Gagal mengambil data (${response.statusCode})");
    }
  }

  // ==================== DELETE SAMPAH ====================
  Future<void> deleteSampah(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token tidak ditemukan.");

    final response = await http.delete(
      Uri.parse('$baseUrl/sampah/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // kalau responsnya bukan 200, artinya gagal hapus
    if (response.statusCode != 200) {
      throw Exception("Gagal menghapus data (${response.statusCode})");
    }
  }

  // ==================== SAVE / UPDATE SAMPAH ====================
  Future<bool> saveSampah(String nama, File? image, {int? id}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token tidak ditemukan.");

    // tentuin POST (baru) atau PUT (edit)
    var request = http.MultipartRequest(
      id == null ? 'POST' : 'PUT',
      Uri.parse(id == null ? '$baseUrl/sampah' : '$baseUrl/sampah/$id'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['nama_sampah'] = nama;

    // kalau ada gambar, lampirkan
    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'pic',
          image.path,
          contentType: http.MediaType('image', 'jpeg'),
        ),
      );
    }

    // kirim request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;  // berhasil
    } else {
      throw Exception("Gagal menyimpan (${response.statusCode}): ${response.body}");
    }
  }
}