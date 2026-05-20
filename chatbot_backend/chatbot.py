from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from transformers import pipeline
from fuzzywuzzy import fuzz
import re

app = FastAPI()

# Izinkan semua origin agar bisa diakses dari emulator (10.0.2.2)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model NLP (pertama kali akan download otomatis)
chatbot_pipeline = pipeline("text-generation", model="microsoft/DialoGPT-medium")

FAQ_DATA = {
    "Apa itu Bank Sampah Sungailiat?": "Bank Sampah Sungailiat adalah program pengelolaan sampah berbasis masyarakat di Sungailiat, Bangka Belitung, yang bertujuan mengurangi sampah melalui daur ulang dan memberikan nilai ekonomis bagi nasabah.",
    "Bagaimana cara menjadi nasabah Bank Sampah Sungailiat?": "Anda dapat mendaftar sebagai nasabah dengan mengunjungi kantor Bank Sampah Sungailiat di Sungailiat, membawa KTP, dan mengisi formulir pendaftaran. Setelah itu, Anda bisa menyetor sampah yang sudah dipilah.",
    "Apa saja layanan Bank Sampah Sungailiat?": "Layanan Bank Sampah Sungailiat meliputi pengumpulan sampah terpilah (plastik, kertas, logam), penimbangan sampah, pencatatan tabungan sampah, serta edukasi tentang pengelolaan sampah dan daur ulang."
}

KEYWORD_SYNONYMS = {
    "cara": ["bagaimana", "gimana", "cara"],
    "akses": ["mengakses", "akses", "buka", "dapatkan"],
    "data": ["data", "informasi", "sampah"]
}

class UserInput(BaseModel):
    message: str

def preprocess_input(message: str) -> str:
    """Normalisasi input: huruf kecil, buang spasi ganda, ganti sinonim."""
    message = re.sub(r'\s+', ' ', message.strip().lower())
    for canonical, synonyms in KEYWORD_SYNONYMS.items():
        for synonym in synonyms:
            message = message.replace(synonym, canonical)
    return message

def find_best_faq_match(user_message: str) -> tuple:
    """Cari FAQ yang paling cocok menggunakan fuzzy matching."""
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
        
        # Fallback: minimal 2 kata kunci yang sama
        if not best_match:
            user_words = set(processed_message.split())
            question_words = set(processed_question.split())
            if len(user_words.intersection(question_words)) >= 2:
                best_match = question
                highest_score = 75
    return best_match, highest_score

@app.post("/chat")
async def chat(user_input: UserInput):
    user_message = user_input.message.strip()
    
    # Cek FAQ dulu
    best_match, score = find_best_faq_match(user_message)
    if best_match and score > 70:
        return {"response": FAQ_DATA[best_match]}
    
    # Kalau tidak ada di FAQ, gunakan model NLP
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
        
        # Hapus bagian input yang kadang ikut muncul
        if response.startswith(user_message):
            response = response[len(user_message):].strip()
        
        if not response:
            response = "Maaf, saya belum bisa menjawab itu. Coba tanyakan yang lain."
        
        return {"response": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")

@app.get("/faq")
async def faq():
    return FAQ_DATA

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)