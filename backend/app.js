// ========== 1. IMPORT ==========
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const db = require('./db');
require('dotenv').config();

// ========== 2. APP ==========
const app = express();
const SECRET_KEY = process.env.JWT_SECRET || "kunci_rahasia_ruang_nada";

// ========== 3. MIDDLEWARE ==========
app.use(express.json());
app.use('/uploads', express.static('uploads'));

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ message: "Token hilang" });
  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.status(403).json({ message: "Token tidak valid" });
    req.user = user;
    next();
  });
};

// ========== 4. UPLOAD ==========
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = './uploads';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir);
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage });

// ========== 5. LOGIN ==========
app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const [rows] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    const user = rows[0];
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(400).json({ message: "Kredensial salah" });
    }
    const token = jwt.sign({ id: user.id, name: user.name }, SECRET_KEY, { expiresIn: '1h' });
    res.json({ token });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ========== 6. CRUD ALAT MUSIK ==========

// CREATE
app.post('/alat-musik', authenticateToken, upload.single('gambar'), async (req, res) => {
  const { nama_alat, kategori, deskripsi, asal_daerah, harga } = req.body;
  const gambar = req.file ? req.file.filename : null;
  try {
    const [result] = await db.execute(
      'INSERT INTO alat_musik (nama_alat, kategori, deskripsi, asal_daerah, harga, gambar) VALUES (?, ?, ?, ?, ?, ?)',
      [nama_alat, kategori, deskripsi, asal_daerah, harga, gambar]
    );
    res.status(201).json({ message: "Alat musik berhasil ditambah", id: result.insertId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// READ ALL
app.get('/alat-musik', authenticateToken, async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM alat_musik');
    // Tambahkan URL gambar
    const data = rows.map(item => ({
      ...item,
      gambar: item.gambar ? `http://192.168.100.222:3000/uploads/${item.gambar}` : null
    }));
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// READ ONE (opsional)
app.get('/alat-musik/:id', authenticateToken, async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT * FROM alat_musik WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: "Data tidak ditemukan" });
    const data = rows[0];
    data.gambar = data.gambar ? `http://192.168.100.222:3000/uploads/${data.gambar}` : null;
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// UPDATE
app.put('/alat-musik/:id', authenticateToken, upload.single('gambar'), async (req, res) => {
  const { id } = req.params;
  const { nama_alat, kategori, deskripsi, asal_daerah, harga } = req.body;
  try {
    const [existing] = await db.execute('SELECT * FROM alat_musik WHERE id = ?', [id]);
    if (existing.length === 0) return res.status(404).json({ message: "Data tidak ditemukan" });

    let query = 'UPDATE alat_musik SET nama_alat = ?, kategori = ?, deskripsi = ?, asal_daerah = ?, harga = ?';
    let params = [
      nama_alat || existing[0].nama_alat,
      kategori || existing[0].kategori,
      deskripsi || existing[0].deskripsi,
      asal_daerah || existing[0].asal_daerah,
      harga || existing[0].harga
    ];

    if (req.file) {
      query += ', gambar = ?';
      params.push(req.file.filename);
      // Hapus gambar lama
      if (existing[0].gambar) {
        const oldPath = path.join(__dirname, 'uploads', existing[0].gambar);
        if (fs.existsSync(oldPath)) fs.unlinkSync(oldPath);
      }
    }

    query += ' WHERE id = ?';
    params.push(id);
    await db.execute(query, params);
    res.json({ message: "Data alat musik berhasil diperbarui" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE
app.delete('/alat-musik/:id', authenticateToken, async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await db.execute('SELECT gambar FROM alat_musik WHERE id = ?', [id]);
    if (rows.length === 0) return res.status(404).json({ message: "Data tidak ditemukan" });

    if (rows[0].gambar) {
      const filePath = path.join(__dirname, 'uploads', rows[0].gambar);
      if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    }
    await db.execute('DELETE FROM alat_musik WHERE id = ?', [id]);
    res.json({ message: "Data alat musik berhasil dihapus" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ========== 7. JALANKAN SERVER ==========
const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server Ruang Nada aktif di http://localhost:${PORT}`);
});