// panggil bcrypt buat ngurus password
const bcrypt = require('bcryptjs');

// password yang mau di-hash (ini cuma contoh, sesuaikan sendiri)
const password = '123456';

// bikin hash-nya, 10 itu tingkat kesulitan (salt rounds)
bcrypt.hash(password, 10, (err, hash) => {
  // kalau ada error, munculin
  if (err) throw err;
  // tampilin hash-nya di terminal
  console.log(hash);
});

// node hash.js untuk menjalkan file ini 