const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',              // sesuaikan user MySQL
  password: '',              // sesuaikan password
  database: 'ruang_nada',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

module.exports = pool;