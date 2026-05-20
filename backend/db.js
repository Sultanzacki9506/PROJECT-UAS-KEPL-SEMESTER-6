// Mengimpor library mysql2 yang mendukung promise dan prepared statements
const mysql = require('mysql2');

// Membuat koneksi pool ke database MySQL
const pool = mysql.createPool({
  host: 'localhost',          // Server MySQL berjalan di komputer lokal
  user: 'root',               // Username default MySQL (Laragon/XAMPP)
  password: '',               // Password default Laragon kosong, isi jika ada
  database: 'nodejs_flutter'  // Nama database yang digunakan
});

// Mengekspor pool dalam mode promise agar bisa pakai async/await
module.exports = pool.promise();