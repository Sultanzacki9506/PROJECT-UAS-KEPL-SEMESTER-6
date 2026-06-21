import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ApiService {
  final String baseUrl = "http://192.168.100.222:3000";
  final String baseUrlNlp = "http://192.168.100.222:8000";
  final String baseUrlFace = "http://192.168.100.222:5000";

  String? _sessionId;

  void resetSession() => _sessionId = null;

  // ==================== CHATBOT ====================
  Future<String> askChatbot(String message) async {
    try {
      final body = <String, dynamic>{'message': message};
      if (_sessionId != null) body['session_id'] = _sessionId;
      final response = await http.post(
        Uri.parse('$baseUrlNlp/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessionId = data['session_id'] ?? _sessionId;
        return data['response'];
      } else {
        return "Maaf, server sedang sibuk.";
      }
    } catch (e) {
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        print('🔐 Login berhasil, token saved');
        return token;
      }
      print(
        '❌ Login gagal, status: ${response.statusCode}, body: ${response.body}',
      );
      return null;
    } catch (e) {
      print('❌ Login exception: $e');
      throw Exception("Gagal login: $e");
    }
  }

  // ==================== FACE RECOGNITION ====================
  Future<Map<String, dynamic>?> recognizeFaceWithConfidence(File image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrlFace/recognize-face'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String label = data['face_label'] ?? 'Unknown';
        double confidence = 0.0;
        if (data['faces'] != null && data['faces'].isNotEmpty) {
          confidence =
              (data['faces'][0]['confidence'] as num?)?.toDouble() ?? 0.0;
        }
        return {'label': label, 'confidence': confidence};
      } else if (response.statusCode == 401) {
        return null;
      } else {
        throw Exception("Server error ${response.statusCode}");
      }
    } catch (e) {
      print("Recognize error: $e");
      return null;
    }
  }

  // ==================== CRUD ALAT MUSIK ====================

  Future<List<AlatMusik>> fetchAlatMusik() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      print('❌ Token tidak ditemukan di SharedPreferences');
      throw Exception("Token tidak ditemukan.");
    }

    print('🔑 Token: $token');

    final response = await http.get(
      Uri.parse('$baseUrl/alat-musik'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('📡 fetchAlatMusik - status: ${response.statusCode}');
    print('📦 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('✅ Jumlah item dari server: ${data.length}');
      return data.map((item) => AlatMusik.fromJson(item)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      print('❌ Token tidak valid atau sesi habis');
      throw Exception("Sesi habis. Silakan login kembali.");
    } else {
      throw Exception(
        "Gagal mengambil data alat musik (${response.statusCode})",
      );
    }
  }

  Future<void> deleteAlatMusik(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token tidak ditemukan.");
    final response = await http.delete(
      Uri.parse('$baseUrl/alat-musik/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('🗑️ deleteAlatMusik($id) status: ${response.statusCode}');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Gagal menghapus (${response.statusCode})");
    }
  }

  Future<bool> saveAlatMusik({
    required String namaAlat,
    required String kategori,
    String deskripsi = '',
    String asalDaerah = '',
    required double harga,
    File? image,
    int? id,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception("Token tidak ditemukan.");

    final uri = id == null
        ? Uri.parse('$baseUrl/alat-musik')
        : Uri.parse('$baseUrl/alat-musik/$id');

    var request = http.MultipartRequest(id == null ? 'POST' : 'PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['nama_alat'] = namaAlat;
    request.fields['kategori'] = kategori;
    request.fields['deskripsi'] = deskripsi;
    request.fields['asal_daerah'] = asalDaerah;
    request.fields['harga'] = harga.toString();

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'gambar',
          image.path,
          contentType: http.MediaType('image', 'jpeg'),
        ),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    print('📡 saveAlatMusik - status: ${response.statusCode}');
    print('📦 Response: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ Data berhasil disimpan');
      return true;
    } else {
      throw Exception(
        "Gagal menyimpan (${response.statusCode}): ${response.body}",
      );
    }
  }
}
