# Terminal 1 - Backend
cd C:\laragon\www\nodejs_flutter\backend
npm install        # hanya pertama kali
node app.js

cd C:\laragon\www\nodejs_flutter\backend
node app.js

# Terminal 2 - Chatbot
cd C:\laragon\www\nodejs_flutter\chatbot_backend
pip install fastapi uvicorn   # hanya pertama kali
python chatbot.py

cd C:\laragon\www\nodejs_flutter\chatbot_backend
venv\Scripts\activate
python chatbot.py

# Terminal 3 - Flutter
cd C:\laragon\www\nodejs_flutter
flutter pub get    # hanya pertama kali
flutter run

cd C:\laragon\www\nodejs_flutter
flutter run

Jalankan kode ini di sql untuk membuat tabel
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL
);


CREATE TABLE sampah (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nama_sampah VARCHAR(255) NOT NULL,
  pic VARCHAR(255)
);