class AlatMusik {
  final int? id;
  final String namaAlat;
  final String kategori;
  final String deskripsi;
  final String asalDaerah;
  final double harga;
  final String? gambarUrl;

  AlatMusik({
    this.id,
    required this.namaAlat,
    required this.kategori,
    this.deskripsi = '',
    this.asalDaerah = '',
    required this.harga,
    this.gambarUrl,
  });

  factory AlatMusik.fromJson(Map<String, dynamic> json) {
    // Parse harga dengan aman (bisa dari String atau num)
    double parsedHarga;
    if (json['harga'] is num) {
      parsedHarga = (json['harga'] as num).toDouble();
    } else {
      parsedHarga = double.tryParse(json['harga']?.toString() ?? '0') ?? 0.0;
    }

    return AlatMusik(
      id: json['id'] as int?,
      namaAlat: json['nama_alat'] ?? '',
      kategori: json['kategori'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      asalDaerah: json['asal_daerah'] ?? '',
      harga: parsedHarga,
      gambarUrl: json['gambar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_alat': namaAlat,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'asal_daerah': asalDaerah,
      'harga': harga,
    };
  }

  AlatMusik copyWith({
    int? id,
    String? namaAlat,
    String? kategori,
    String? deskripsi,
    String? asalDaerah,
    double? harga,
    String? gambarUrl,
  }) {
    return AlatMusik(
      id: id ?? this.id,
      namaAlat: namaAlat ?? this.namaAlat,
      kategori: kategori ?? this.kategori,
      deskripsi: deskripsi ?? this.deskripsi,
      asalDaerah: asalDaerah ?? this.asalDaerah,
      harga: harga ?? this.harga,
      gambarUrl: gambarUrl ?? this.gambarUrl,
    );
  }
}