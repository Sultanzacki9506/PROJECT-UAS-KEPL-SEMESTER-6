from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from transformers import pipeline
from fuzzywuzzy import fuzz
import uuid
from collections import defaultdict
import re
import random

app = FastAPI()

# CORS – izinkan semua origin (development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model NLP (DialoGPT-medium)
chatbot_pipeline = pipeline("text-generation", model="microsoft/DialoGPT-medium")

# Penyimpanan sesi in-memory
sessions = defaultdict(lambda: {"history": [], "last_intent": None})

# ============= FAQ UNTUK RUANG NADA (ALAT MUSIK) =============
FAQ_DATA = {
    "Apa itu Ruang Nada?": 
        "Ruang Nada adalah aplikasi berbasis Flutter untuk mengelola data alat musik. Anda bisa menambah, melihat, mengedit, dan menghapus informasi alat musik seperti nama, kategori, asal daerah, harga, dan foto.",
    
    "Bagaimana cara menambahkan alat musik?": 
        "Buka halaman utama, lalu tekan tombol '+'. Isi form dengan nama alat, kategori, asal daerah, harga, dan foto (opsional). Klik 'Simpan' untuk menambahkan data.",
    
    "Apa saja kategori alat musik yang tersedia?": 
        "Kategori yang tersedia: Dawai, Tiup, Perkusi, Keyboard, Elektronik, dan Lainnya. Anda bisa memilih salah satu saat menambah atau mengedit data.",
    
    "Bagaimana cara mengedit data alat musik?": 
        "Pada halaman daftar alat musik, klik card alat yang ingin diedit. Form akan terisi otomatis, ubah data yang diinginkan, lalu klik 'Simpan Perubahan'.",
    
    "Bagaimana cara menghapus alat musik?": 
        "Di halaman daftar, klik ikon tempat sampah (hapus) pada card alat musik. Konfirmasi penghapusan, lalu data akan dihapus dari database.",
    
    "Apa itu asal daerah pada alat musik?": 
        "Asal daerah merujuk pada daerah atau budaya di mana alat musik tersebut berasal, misalnya 'Jawa Barat' untuk angklung, atau 'Sumatera Utara' untuk gondang.",
    
    "Bagaimana cara melihat daftar semua alat musik?": 
        "Setelah login, Anda akan langsung masuk ke halaman dashboard yang menampilkan semua alat musik yang tersimpan dalam bentuk card.",
    
    "Apa yang dimaksud dengan harga alat musik?": 
        "Harga adalah nilai nominal (dalam Rupiah) yang tercantum untuk alat musik tersebut. Biasanya harga pasar atau perkiraan nilai jual.",
    
    "Bagaimana cara mencari alat musik?": 
        "Pada dashboard, gunakan kolom pencarian di bagian atas. Ketik nama alat yang dicari, daftar akan otomatis tersaring.",
    
    "Apakah foto alat musik wajib diisi?": 
        "Tidak, foto bersifat opsional. Anda bisa menambahkan foto dari galeri untuk memperjelas tampilan alat musik.",
    
    "Siapa yang bisa mengakses aplikasi Ruang Nada?": 
        "Pengguna yang telah login dengan akun yang terdaftar. Saat ini pendaftaran hanya melalui admin.",
    
    "Apa saja fitur unggulan Ruang Nada?": 
        "Fitur unggulan: CRUD alat musik, pencarian, face login, dan chatbot interaktif untuk membantu pengguna.",
}

# Sinonim kata kunci untuk pencocokan lebih luwes
KEYWORD_SYNONYMS = {
    "tambah": ["tambah", "input", "buat", "add", "masukkan"],
    "edit": ["edit", "ubah", "perbarui", "update", "ganti"],
    "hapus": ["hapus", "delete", "hilangkan", "buang"],
    "cari": ["cari", "temukan", "filter", "search"],
    "daftar": ["daftar", "list", "semua", "tampilkan"],
    "kategori": ["kategori", "jenis", "tipe"],
    "harga": ["harga", "biaya", "nilai"],
    "asal": ["asal", "daerah", "tempat", "berasal"],
}

def preprocess_input(message: str) -> str:
    """Normalisasi input: lowercase, hapus spasi berlebih, ubah sinonim."""
    message = re.sub(r'\s+', ' ', message.strip().lower())
    for canonical, synonyms in KEYWORD_SYNONYMS.items():
        for synonym in synonyms:
            message = message.replace(synonym, canonical)
    return message

def find_best_faq_match(user_message: str) -> tuple:
    """Cocokkan pertanyaan dengan FAQ menggunakan fuzzy matching."""
    best_match = None
    highest_score = 0
    processed_message = preprocess_input(user_message)

    for question in FAQ_DATA:
        processed_question = preprocess_input(question)
        partial_score = fuzz.partial_ratio(processed_message, processed_question)
        token_sort_score = fuzz.token_sort_ratio(processed_message, processed_question)
        ratio_score = fuzz.ratio(processed_message, processed_question)
        combined_score = (partial_score * 0.5 + token_sort_score * 0.3 + ratio_score * 0.2)

        if combined_score > 70 and combined_score > highest_score:
            best_match = question
            highest_score = combined_score

    # Jika tidak ada yang di atas 70, coba minimal 2 kata kunci sama
    if not best_match:
        user_words = set(processed_message.split())
        for question in FAQ_DATA:
            question_words = set(preprocess_input(question).split())
            if len(user_words.intersection(question_words)) >= 2:
                best_match = question
                highest_score = 75
                break

    return best_match, highest_score

def generate_ai_response(user_message: str) -> str:
    """Respons menggunakan model AI jika tidak ada FAQ yang cocok."""
    try:
        response = chatbot_pipeline(
            user_message,
            max_length=150,
            num_return_sequences=1,
            do_sample=True,
            top_p=0.9,
            temperature=0.7,
            pad_token_id=chatbot_pipeline.tokenizer.eos_token_id
        )[0]["generated_text"]

        if response.startswith(user_message):
            response = response[len(user_message):].strip()

        if not response:
            return "Maaf, saya belum bisa menjawab itu. Coba tanyakan yang lain."
        return response
    except Exception:
        return "Maaf, sedang ada gangguan teknis. Silakan coba lagi nanti."

def is_greeting(message: str) -> bool:
    greetings = [
        "halo", "hai", "hei", "hi", "hey",
        "selamat pagi", "selamat siang", "selamat sore", "selamat malam",
        "assalamualaikum", "assalam", "salam"
    ]
    msg = message.lower().strip()
    return any(greet in msg for greet in greetings)

def get_greeting_response() -> str:
    responses = [
        "Halo! Selamat datang di Ruang Nada – aplikasi manajemen alat musik. Ada yang bisa saya bantu?",
        "Hai! Siap membantu Anda mengelola data alat musik di Ruang Nada.",
        "Halo! Silakan tanyakan seputar alat musik atau fitur aplikasi.",
        "Assalamualaikum! Ada yang bisa saya bantu terkait Ruang Nada?"
    ]
    return random.choice(responses)

# ─── ENDPOINT CHAT ──────────────────────────────────────────────
class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    session_id: str

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    user_message = request.message.strip()
    if not user_message:
        return ChatResponse(response="Silakan ketik sesuatu.", session_id=request.session_id or "")

    session_id = request.session_id or str(uuid.uuid4())
    session = sessions[session_id]

    # Tangani sapaan
    if is_greeting(user_message):
        greeting_resp = get_greeting_response()
        session["history"].append({"user": user_message, "bot": greeting_resp, "intent": "greeting"})
        session["last_intent"] = "greeting"
        return ChatResponse(response=greeting_resp, session_id=session_id)

    # Cek FAQ
    best_match, score = find_best_faq_match(user_message)
    if best_match and score > 70:
        response_text = FAQ_DATA[best_match]
    else:
        # Fallback ke AI
        response_text = generate_ai_response(user_message)
        if not response_text:
            response_text = "Maaf, saya belum mengerti. Coba tanyakan dengan kata kunci yang lebih jelas."

    session["history"].append({
        "user": user_message,
        "bot": response_text,
        "intent": "faq" if best_match else "ai"
    })
    session["last_intent"] = "faq" if best_match else "ai"

    return ChatResponse(response=response_text, session_id=session_id)

# ─── ENDPOINT FAQ ───────────────────────────────────────────────
@app.get("/faq")
async def faq():
    return FAQ_DATA

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)