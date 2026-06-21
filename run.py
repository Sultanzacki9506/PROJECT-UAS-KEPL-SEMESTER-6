import dlib
import cv2
import numpy as np
from scipy.spatial import distance
from flask import Flask, request, jsonify
import joblib
from jose import jwt
import datetime

# ====================== KONFIGURASI ======================
SHAPE_PREDICTOR = "shape_predictor_68_face_landmarks.dat"
FACE_RECOG_MODEL = "dlib_face_recognition_resnet_model_v1.dat"
SECRET_KEY = "kunci_super_rahasia_2025"   # Ganti dengan key yang aman

detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(SHAPE_PREDICTOR)
face_rec_model = dlib.face_recognition_model_v1(FACE_RECOG_MODEL)

# Muat model training
knn = joblib.load('knn_model.pkl')
le = joblib.load('label_encoder.pkl')
X_train = np.load('face_encodings.npy')   # opsional, tidak dipakai langsung

# ====================== FUNGSI ======================
def get_face_encoding(image, face):
    shape = predictor(image, face)
    return np.array(face_rec_model.compute_face_descriptor(image, shape))

def generate_token(user_id):
    payload = {
        'user_id': user_id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')

def verify_token(token):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        return payload['user_id']
    except:
        return None

app = Flask(__name__)

@app.route('/login', methods=['POST'])
def login():
    # Contoh login statis – bisa diganti dengan validasi database
    user_id = '123'
    if user_id:
        token = generate_token(user_id)
        return jsonify({'status': 'success', 'token': token})
    return jsonify({'status': 'fail', 'message': 'Invalid credentials'}), 401

@app.route('/recognize-face', methods=['POST'])
def recognize_face():
    # (Opsional) Verifikasi token – dihilangkan agar mudah testing
    # token = request.headers.get('Authorization')
    # if not token or verify_token(token) is None:
    #     return jsonify({'status': 'fail', 'message': 'Token tidak valid'}), 403

    if 'image' not in request.files:
        return jsonify({'status': 'fail', 'message': 'File gambar tidak ada'}), 400

    file = request.files['image']
    img_array = np.frombuffer(file.read(), np.uint8)
    image = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    faces = detector(rgb)
    results = []

    for face in faces:
        encoding = get_face_encoding(rgb, face)
        encoding_2d = encoding.reshape(1, -1)
        pred_encoded = knn.predict(encoding_2d)[0]
        pred_name = le.inverse_transform([pred_encoded])[0]

        distances, _ = knn.kneighbors(encoding_2d, n_neighbors=min(3, len(X_train)) if len(X_train) > 0 else 1)
        
        # Jarak euclidian standar dlib untuk wajah yang sama adalah <= 0.6
        # Karena dataset masih sedikit, kita set threshold jarak yang JAUH lebih ketat: 0.38
        jarak_terdekat = distances[0][0]
        confidence = 1 / (1 + jarak_terdekat)
        
        # Jika jarak lebih dari 0.38, anggap Unknown
        label = pred_name if jarak_terdekat < 0.38 else "Unknown"

        results.append({
            'label': label,
            'confidence': round(float(confidence), 3),
            'distance': round(float(jarak_terdekat), 3)
        })

    if not results:
        return jsonify({'status': 'fail', 'message': 'Tidak ada wajah terdeteksi'}), 400

    best = max(results, key=lambda x: x['confidence'])
    if best['label'] == "Unknown":
        return jsonify({'status': 'fail', 'message': 'Wajah tidak dikenali', 'faces': results}), 401

    return jsonify({'status': 'success', 'faces': results, 'face_label': best['label']})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)