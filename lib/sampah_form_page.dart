import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class SampahFormPage extends StatefulWidget {
  final Map? sampah; // null kalau insert, ada isi kalau update

  const SampahFormPage({super.key, this.sampah});

  @override
  _SampahFormPageState createState() => _SampahFormPageState();
}

class _SampahFormPageState extends State<SampahFormPage> {
  final _formKey = GlobalKey<FormState>(); // kunci buat validasi form
  final _controller = TextEditingController(); // kontrol input nama sampah
  File? _image; // nyimpen file gambar yang dipilih
  final ImagePicker _picker = ImagePicker(); // akses galeri/kamera
  bool _isSaving = false; // status lagi nyimpen (biar tombol gak dobel klik)

  @override
  void initState() {
    super.initState();
    if (widget.sampah != null) {
      // kalau edit, isi dulu field nama dengan data lama
      _controller.text = widget.sampah!['nama_sampah'];
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, // ambil dari galeri
        imageQuality: 50, // kompres biar ukuran file gak kegedean
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path); // simpan file gambar yang udah dipilih
        });
      }
    } catch (e) {
      if (!mounted) return; // jangan lanjut kalau layar udah ditutup
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil gambar: $e")),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return; // validasi form, stop kalau gak lolos

    setState(() => _isSaving = true); // mulai loading
    try {
      bool success = await ApiService().saveSampah(
        _controller.text,
        _image,
        id: widget.sampah?['id'], // kirim id kalau edit
      );

      if (!mounted) return;
      setState(() => _isSaving = false); // loading selesai

      if (success) {
        Navigator.pop(context, true); // balik ke dashboard sambil bawa true (refresh)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil disimpan")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sampah == null ? "Entry Data" : "Edit Data"), // judul dinamis
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Informasi Sampah",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "Nama Sampah",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Nama harus diisi" : null,
              ),
              const SizedBox(height: 20),
              const Text("Foto Sampah", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage, // sentuh area ini buka galeri
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_image!, fit: BoxFit.cover), // tampilkan gambar terpilih
                        )
                      : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey), // placeholder
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSaving ? null : _submit, // matiin tombol pas lagi nyimpen
                  child: _isSaving
                      ? const SizedBox( // spinner kecil pas loading
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "SIMPAN DATA",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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