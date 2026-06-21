# Terminal 1 - Backend
cd C:\laragon\www\nodejs_flutter\backend
npm install        # hanya pertama kali
node app.js

cd C:\laragon\www\nodejs_flutter\backend
node app.js

# Terminal 2 - Chatbot
cd C:\laragon\www\nodejs_flutter\chatbot_backend
pip install fastapi uvicorn   # hanya pertama kali

venv\Scripts\activate
python chatbot.py

# Terminal 3 - Face Id
cd C:\laragon\www\nodejs_flutter
python run.py

# Terminal 4 - Flutter
cd C:\laragon\www\nodejs_flutter
flutter clean
flutter pub cache repair

rmdir /s /q %USERPROFILE%\AppData\Local\Pub\Cache
flutter pub get

dart run flutter_launcher_icons
flutter pub run flutter_launcher_icons

flutter clean
flutter pub get

cd C:\laragon\www\nodejs_flutter\backend
node add_user_hash.js

# Terminal 5 - Training Face
 python train.py
