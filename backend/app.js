// 1. IMPORT SEMUA LIBRARY YANG DIBUTUHKAN
const express = require('express');     // buat bikin server web
const jwt = require('jsonwebtoken');    // buat bikin & cek token login
const bcrypt = require('bcryptjs');     // buat nge-hash & ngecek password
const multer = require('multer');       // buat handle upload file/gambar
const path = require('path');           // buat ngolah path file
const fs = require('fs');               // buat ngurus file system (hapus file, dll)
const db = require('./db');             // koneksi ke database MySQL
require('dotenv').config();             // baca file .env (biar JWT_SECRET aman)

// 2. INISIALISASI APP
const app = express();
const SECRET_KEY = process.env.JWT_SECRET || "kunci_rahasia_bank_sampah";
// kunci buat bikin token, ambil dari .env, kalau gak ada pakai default

// 3. MIDDLEWARE
app.use(express.json());                // biar backend bisa baca JSON dari request
app.use('/uploads', express.static('uploads')); // biar file di folder uploads bisa diakses publik

// Middleware Otorisasi JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization']; // ambil header Authorization
  const token = authHeader && authHeader.split(' ')[1]; // ambil token setelah "Bearer"
  if (!token) return res.status(401).json({ message: "Token hilang" }); // gak ada token = 401
  jwt.verify(token, SECRET_KEY, (err, user) => { // cek token asli atau palsu
    if (err) return res.status(403).json({ message: "Token tidak valid" }); // token gak valid = 403
    req.user = user; // simpan data user di request
    next(); // lanjut ke route berikutnya
  });
};

// 4. KONFIGURASI MULTER (UPLOAD GAMBAR)
const storage = multer.diskStorage({
  destination: (req, file, cb) => { // tentukan folder penyimpanan
    const dir = './uploads';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir); // kalau folder belum ada, bikin dulu
    cb(null, dir);
  },
  filename: (req, file, cb) => { // bikin nama file unik: timestamp + ekstensi asli
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage: storage }); // siap upload

// 5. ROUTES LOGIN
app.post('/login', async (req, res) => {
  const { email, password } = req.body; // ambil email & password dari request
  try {
    const [rows] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    const user = rows[0]; // ambil user pertama (email harus unik)
    // kalau user gak ketemu atau password gak cocok
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(400).json({ message: "Kredensial salah" });
    }
    // bikin token berlaku 1 jam
    const token = jwt.sign({ id: user.id }, SECRET_KEY, { expiresIn: '1h' });
    res.json({ token }); // kirim token ke Flutter
  } catch (err) {
    res.status(500).json({ error: err.message }); // error server
  }
});

// 6. ROUTES CRUD SAMPAH

// CREATE - tambah data sampah (perlu login & upload gambar)
app.post('/sampah', authenticateToken, upload.single('pic'), async (req, res) => {
  const { nama_sampah } = req.body; // ambil nama sampah dari form
  const pic = req.file ? req.file.filename : null; // kalau ada gambar, simpan nama file
  try {
    const [result] = await db.execute(
      'INSERT INTO sampah (nama_sampah, pic) VALUES (?, ?)',
      [nama_sampah, pic]
    );
    res.status(201).json({ message: "Data berhasil ditambah", id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// READ ALL - ambil semua data sampah (perlu login)
app.get('/sampah', authenticateToken, async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM sampah');
    // tambahin pic_url biar Flutter bisa langsung akses gambar dari HP
    const dataDenganUrl = rows.map(item => ({
      ...item,
      pic_url: item.pic ? `http://192.168.18.2:3000/uploads/${item.pic}` : null  // ganti IP sesuai laptop
    }));
    res.json(dataDenganUrl);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// READ ONE - ambil satu data sampah berdasarkan ID
app.get('/sampah/:id', authenticateToken, async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM sampah WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: "Data tidak ditemukan" });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE - edit data sampah (bisa ganti nama & gambar)
app.put('/sampah/:id', authenticateToken, upload.single('pic'), async (req, res) => {
  const { id } = req.params;
  const { nama_sampah } = req.body;
  try {
    const [existing] = await db.execute('SELECT * FROM sampah WHERE id = ?', [id]);
    if (existing.length === 0) return res.status(404).json({ message: "Data tidak ditemukan" });

    let query = 'UPDATE sampah SET nama_sampah = ?';
    let params = [nama_sampah || existing[0].nama_sampah]; // kalau gak diisi, pakai yang lama

    if (req.file) { // kalau ada gambar baru
      query += ', pic = ?';
      params.push(req.file.filename);
      if (existing[0].pic) { // hapus gambar lama
        const oldPath = path.join(__dirname, 'uploads', existing[0].pic);
        if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
      }
    }

    query += ' WHERE id = ?';
    params.push(id);
    await db.execute(query, params);
    res.json({ message: "Data sampah berhasil diperbarui" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE - hapus data sampah beserta gambar
app.delete('/sampah/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await db.execute('SELECT pic FROM sampah WHERE id = ?', [id]);
    if (rows.length === 0) return res.status(404).json({ message: "Data tidak ditemukan" });

    if (rows[0].pic) { // hapus file gambar dari folder uploads
      const filePath = path.join(__dirname, 'uploads', rows[0].pic);
      if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    }
    await db.execute('DELETE FROM sampah WHERE id = ?', [id]);
    res.json({ message: "Data sampah dan file gambar berhasil dihapus" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 7. JALANKAN SERVER
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Server aktif di http://localhost:${PORT}`); // muncul di terminal
});