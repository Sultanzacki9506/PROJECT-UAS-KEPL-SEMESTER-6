# Ruang Nada 🎵

<<<<<<< HEAD
**Ruang Nada** adalah aplikasi manajemen alat musik nusantara yang interaktif. Aplikasi ini dilengkapi dengan fitur keamanan **Face Recognition** untuk otentikasi login serta **AI Chatbot** yang bertindak sebagai asisten pintar untuk mengeksplorasi data alat musik.
=======
**Ruang Nada** adalah aplikasi manajemen alat musik nusantara yang interaktif. Aplikasi ini dilengkapi dengan fitur keamanan **Face Recognition** untuk otentikasi login serta **AI Chatbot** yang bertindak sebagai asisten pintar untuk mengeksplorasi data alat musik. 
>>>>>>> 90754316bc34a79774bcbacd1b6585c529736793

Proyek ini dikembangkan sebagai bentuk pemenuhan Tugas Project Kelompok pada Mata Kuliah **Konstruksi dan Evolusi Perangkat Lunak (KEPL)** Semester 6.

---

## 👥 Anggota Kelompok
<<<<<<< HEAD

1. **Archie Arya Manggala**
2. **Fionalita Rachmadianti**
3. **Sultan Zacki Dariansyah**

---

## 🌟 Fitur Utama

- **Face Login (Biometrik):** Sistem autentikasi canggih menggunakan pemrosesan gambar dan model KNN (_K-Nearest Neighbors_) via pustaka Dlib ResNet.
- **Manajemen Alat Musik (CRUD):** Tambah, baca, ubah, hapus (termasuk upload gambar kamera/galeri) untuk direktori alat musik Nusantara.
- **Asisten AI Chatbot:** Chatbot cerdas untuk membantu pengguna mencari informasi umum dan interaksi bantuan seputar instrumen.
- **Premium UI/UX:** Antarmuka responsif dan modern dengan _Shimmer Loading_, efek _Glassmorphism_, _Pull-to-Refresh_, serta animasi transisi yang mulus.
=======
1. **Archie Arya Manggala**
2. **Fionalita Rachmadianti**
3. **Sultan Zacki Dariansyah**

---

## 🌟 Fitur Utama
- **Face Login (Biometrik):** Sistem autentikasi canggih menggunakan pemrosesan gambar dan model KNN (*K-Nearest Neighbors*) via pustaka Dlib ResNet.
- **Manajemen Alat Musik (CRUD):** Tambah, baca, ubah, hapus (termasuk upload gambar kamera/galeri) untuk direktori alat musik Nusantara.
- **Asisten AI Chatbot:** Chatbot cerdas untuk membantu pengguna mencari informasi umum dan interaksi bantuan seputar instrumen.
- **Premium UI/UX:** Antarmuka responsif dan modern dengan *Shimmer Loading*, efek *Glassmorphism*, *Pull-to-Refresh*, serta animasi transisi yang mulus.
>>>>>>> 90754316bc34a79774bcbacd1b6585c529736793

---

## 🛠️ Tech Stack & Arsitektur
<<<<<<< HEAD

Sistem ini menggunakan arsitektur modular yang terdiri dari 4 layanan utama:

=======
Sistem ini menggunakan arsitektur modular yang terdiri dari 4 layanan utama:
>>>>>>> 90754316bc34a79774bcbacd1b6585c529736793
1. **Frontend App:** Flutter & Dart
2. **Database Backend:** Node.js, Express.js, & MySQL (Port 3000)
3. **Face ID API:** Python, Flask, Dlib, OpenCV, Scikit-Learn (Port 5000)
4. **Chatbot API:** Python, FastAPI, Uvicorn (Port 8000)

---

## 🚀 Cara Menjalankan Aplikasi (Local Setup)

<<<<<<< HEAD
Untuk menjalankan aplikasi Ruang Nada secara _full-stack_, Anda perlu menjalankan seluruh _services_ di terminal yang terpisah.

> **Catatan Penting:** Pastikan alamat IP lokal pada file `lib/api_service.dart` dan `backend/app.js` sudah sesuai dengan alamat IP IPv4 komputer host Anda (misalnya `192.168.77.72`).

### Terminal 1: Backend Database (Node.js)

=======
Untuk menjalankan aplikasi Ruang Nada secara *full-stack*, Anda perlu menjalankan seluruh *services* di terminal yang terpisah. 

> **Catatan Penting:** Pastikan alamat IP lokal pada file `lib/api_service.dart` dan `backend/app.js` sudah sesuai dengan alamat IP IPv4 komputer host Anda (misalnya `192.168.100.222`).

### Terminal 1: Backend Database (Node.js)
>>>>>>> 90754316bc34a79774bcbacd1b6585c529736793
```bash
cd backend
npm install   # (Hanya untuk pertama kali)
node app.js
```

### Terminal 2: Chatbot API (Python FastAPI)
<<<<<<< HEAD

=======
>>>>>>> 90754316bc34a79774bcbacd1b6585c529736793
```bash
cd chatbot_backend
venv\Scripts\activate            # (Opsional: Aktifkan Virtual Environment jika ada)
pip install fastapi uvicorn      # (Hanya untuk pertama kali)
python chatbot.py
```

### Terminal 3: Face ID Service (Python Flask)
<<<<<<< HEAD

=======
>>>>>>> 90754316bc34a79774bcbacd1b6585c529736793
```bash
# Pastikan Anda berada di root project Ruang Nada
python run.py
```

### Terminal 4: Aplikasi Mobile (Flutter)
<<<<<<< HEAD

=======
>>>>>>> 90754316bc34a79774bcbacd1b6585c529736793
```bash
# Pastikan Anda berada di root project Ruang Nada
flutter pub get
flutter run
```

---

## 👤 Cara Melatih Ulang Data Wajah (Training Face ID)
<<<<<<< HEAD

Jika Anda ingin menambahkan anggota tim baru atau mengoptimalkan akurasi pengenalan wajah:

=======
Jika Anda ingin menambahkan anggota tim baru atau mengoptimalkan akurasi pengenalan wajah:
>>>>>>> 90754316bc34a79774bcbacd1b6585c529736793
1. Tambahkan folder dengan **Nama Anda** (contoh: `Sultan`) ke dalam direktori `training_faces/`.
2. Masukkan minimal 5-10 foto wajah terbaru yang jelas di dalam folder tersebut.
3. Buka Terminal baru, lalu jalankan:
   ```bash
   python train.py
   ```
4. Setelah proses selesai, model `knn_model.pkl` akan diperbarui secara otomatis. Anda wajib me-restart file `run.py` (Terminal 3) untuk memuat model yang baru.

---
<<<<<<< HEAD

_© 2026 - Ruang Nada Team_
=======
*© 2026 - Ruang Nada Team*
>>>>>>> 90754316bc34a79774bcbacd1b6585c529736793
