from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uuid
from collections import defaultdict

app = FastAPI()

# Izinkan semua origin (untuk development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Penyimpanan sesi sederhana (in-memory)
sessions = defaultdict(lambda: {"history": [], "last_intent": None})

# ========== MODEL REQUEST & RESPONSE ==========
class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None  # ID sesi untuk melacak percakapan

class ChatResponse(BaseModel):
    response: str
    session_id: str

# ========== DETEKSI INTENT ==========
def detect_intent(message: str) -> str:
    msg = message.lower().strip()

    # Salam / greeting
    if any(word in msg for word in ["halo", "hai", "hei", "hi", "selamat", "assalam"]):
        return "greeting"

    # Harga
    if any(word in msg for word in ["harga", "tarif", "biaya", "beli", "jual", "nilai"]):
        return "price"

    # Jadwal / operasional
    if any(word in msg for word in ["jadwal", "buka", "tutup", "jam", "operasional", "hari"]):
        return "schedule"

    # Jenis sampah
    if any(word in msg for word in ["jenis", "macam", "kategori", "tipe", "sampah", "organik", "anorganik", "b3", "plastik", "kertas", "logam"]):
        return "waste_type"

    # Prosedur / cara menabung
    if any(word in msg for word in ["cara", "bagaimana", "menabung", "setor", "prosedur", "syarat", "daftar"]):
        return "procedure"

    # Lokasi
    if any(word in msg for word in ["lokasi", "alamat", "maps", "tempat", "posisi", "di mana"]):
        return "location"

    # Terima kasih
    if any(word in msg for word in ["terima kasih", "thanks", "makasih", "thank"]):
        return "thanks"

    # Bantuan
    if any(word in msg for word in ["bantuan", "help", "info", "tanya", "faq"]):
        return "help"

    # Tambahan: sapaan perpisahan
    if any(word in msg for word in ["bye", "selamat tinggal", "dadah"]):
        return "bye"

    return "unknown"

# ========== GENERATE RESPONS ==========
def generate_response(intent: str, message: str, session: dict) -> str:
    last_intent = session.get("last_intent")

    if intent == "greeting":
        return "Halo! Selamat datang di Bank Sampah. Ada yang bisa saya bantu?"

    elif intent == "price":
        if "plastik" in message:
            return "Harga sampah plastik berkisar Rp 500 - Rp 2.000 per kg, tergantung jenis dan kebersihannya."
        elif "kertas" in message:
            return "Harga kertas bekas sekitar Rp 800 - Rp 1.500 per kg."
        elif "logam" in message or "besi" in message:
            return "Logam seperti besi dihargai Rp 2.000 - Rp 5.000 per kg."
        else:
            return "Harga sampah bervariasi. Sebutkan jenisnya (plastik, kertas, logam, dll) atau cek di aplikasi kami."

    elif intent == "schedule":
        return "Bank Sampah buka Senin - Sabtu, pukul 08.00 - 16.00. Hari Minggu & libur nasional tutup."

    elif intent == "waste_type":
        return (
            "Kami menerima:\n"
            "• Organik: sisa makanan, daun\n"
            "• Anorganik: plastik, kertas, logam, kaca\n"
            "• B3: baterai, lampu, elektronik\n\n"
            "Silakan pilah dulu sebelum disetor."
        )

    elif intent == "procedure":
        return (
            "Cara menabung sampah:\n"
            "1. Pilah sesuai jenisnya\n"
            "2. Bersihkan & keringkan\n"
            "3. Bawa ke Bank Sampah\n"
            "4. Timbang & dapat saldo\n\n"
            "Bisa juga daftar nasabah lewat aplikasi."
        )

    elif intent == "location":
        return "🏢 Bank Sampah beralamat di Polman Babel. Lihat peta di aplikasi."

    elif intent == "thanks":
        return "Sama-sama! Jangan ragu bertanya lagi. 🌱"

    elif intent == "help":
        return "Saya bisa bantu soal:\n- Harga\n- Jadwal\n- Jenis sampah\n- Cara menabung\n- Lokasi\nSilakan tanya."

    elif intent == "bye":
        return "Terima kasih sudah bertanya. Sampai jumpa! 👋"

    else:
        # Fallback dengan konteks
        if last_intent and last_intent != "unknown":
            return f"Maaf, saya belum mengerti. Anda sebelumnya tanya tentang *{last_intent}*. Bisa lebih spesifik?"
        else:
            return "Maaf, saya belum mengerti. Ketik 'bantuan' untuk lihat topik yang bisa saya jawab."

# ========== ROUTE /CHAT ==========
@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    # Dapatkan atau buat session_id baru
    session_id = request.session_id or str(uuid.uuid4())
    session = sessions[session_id]

    # Deteksi intent
    intent = detect_intent(request.message)

    # Generate respons
    response_text = generate_response(intent, request.message, session)

    # Update session
    session["history"].append({
        "user": request.message,
        "bot": response_text,
        "intent": intent
    })
    session["last_intent"] = intent

    return ChatResponse(response=response_text, session_id=session_id)


# ========== JALANKAN SERVER ==========
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)