import 'package:flutter/material.dart';
import 'api_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController(); // kontrol input teks
  final List<Map<String, dynamic>> _messages = []; // daftar pesan (user & bot)
  bool _isTyping = false; // buat nunjukin chatbot lagi "ngetik"

  // Fungsi kirim pesan
  void _sendMessage() async {
    if (_controller.text.isEmpty) return; // kalo kosong gak usah dikirim

    final String userMsg = _controller.text;
    setState(() {
      _messages.add({"text": userMsg, "isUser": true}); // tambah pesan user
      _isTyping = true; // tunjukin indikator loading
    });
    _controller.clear(); // kosongin input

    try {
      final String botRes = await ApiService().askChatbot(userMsg); // panggil API chatbot
      if (!mounted) return; // jangan lanjut kalo halaman udah ditutup
      setState(() {
        _messages.add({"text": botRes, "isUser": false}); // tambah balasan bot
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          "text": "❌ Gagal terhubung ke chatbot. Cek server.", // pesan error kalo gagal
          "isUser": false,
        });
      });
    } finally {
      if (mounted) {
        setState(() => _isTyping = false); // matiin indikator loading
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tanya Bank Sampah"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] == true; // cek siapa pengirim
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, // rata kanan kalo user, kiri kalo bot
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green[100] : Colors.grey[200], // warna beda
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: msg['text'].toString().startsWith('❌')
                            ? Colors.red   // merah kalo pesan error
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping) const LinearProgressIndicator(color: Colors.green), // loading bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Tanya sesuatu...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: _isTyping ? null : (_) => _sendMessage(), // kirim kalo pencet enter
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isTyping ? null : _sendMessage, // matiin tombol kalo lagi ngetik
                  mini: true,
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}