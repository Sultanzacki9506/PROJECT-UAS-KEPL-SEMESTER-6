const bcrypt = require('bcryptjs');
const db = require('./db');

async function addUsers() {
  const users = [
    { email: 'archie@gmail.com', password: '123456', name: 'Archie' },
    { email: 'sultan@gmail.com', password: '123456', name: 'Sultan' },
    { email: 'fionalita@gmail.com', password: '123456', name: 'Fionalita' }
  ];

  for (let u of users) {
    const hashed = await bcrypt.hash(u.password, 10);
    // Cek apakah user sudah ada
    const [existing] = await db.execute('SELECT * FROM users WHERE email = ?', [u.email]);
    if (existing.length > 0) {
      // Update password
      await db.execute('UPDATE users SET password = ? WHERE email = ?', [hashed, u.email]);
      console.log(`Password ${u.email} diupdate.`);
    } else {
      // Insert baru
      await db.execute('INSERT INTO users (email, password, name) VALUES (?, ?, ?)', [u.email, hashed, u.name]);
      console.log(`User ${u.email} ditambahkan.`);
    }
  }
  process.exit();
}

addUsers();