import time
from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from database import get_db_connection

auth_bp = Blueprint('auth', __name__)

def user_dict(row):
    """Zwraca słownik użytkownika bez pola hasła."""
    return {
        "username": row["username"],
        "bio": row["bio"] or "uzytkownik pluma",
        "pfp": row["pfp"] or "assets/logo-kogut-500x500.png",
        "banner": row["banner"] or "assets/bliss-1024p.jpg",
        "color": row["color"] or "#ffb870",
        "createdAt": row["createdAt"] or int(time.time() * 1000),
    }

@auth_bp.route("/auth/register", methods=["POST"])
def register():
    """Rejestracja nowego użytkownika z hashowanym hasłem."""
    data = request.json or {}
    username = (data.get("username") or "").strip().lower().replace("@", "")
    password = data.get("password") or ""

    if not username:
        return jsonify({"status": "error", "message": "Nazwa użytkownika nie może być pusta"}), 400
    if len(password) < 4:
        return jsonify({"status": "error", "message": "Hasło musi mieć co najmniej 4 znaki"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT username FROM users WHERE username = ?", (username,))
    if cursor.fetchone():
        conn.close()
        return jsonify({"status": "error", "message": "Użytkownik już istnieje. Zaloguj się."}), 409

    now = int(time.time() * 1000)
    pw_hash = generate_password_hash(password)
    cursor.execute("""
        INSERT INTO users (username, bio, pfp, banner, color, createdAt, password_hash)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (username, "uzytkownik pluma", "assets/logo-kogut-500x500.png",
          "assets/bliss-1024p.jpg", "#ffb870", now, pw_hash))
    conn.commit()

    cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
    row = cursor.fetchone()
    conn.close()
    return jsonify({"status": "success", "message": "Rejestracja udana", "user": user_dict(row)}), 201

@auth_bp.route("/auth/login", methods=["POST"])
def login():
    """Logowanie użytkownika z weryfikacją hasła."""
    data = request.json or {}
    username = (data.get("username") or "").strip().lower().replace("@", "")
    password = data.get("password") or ""

    if not username:
        return jsonify({"status": "error", "message": "Nazwa użytkownika nie może być pusta"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
    row = cursor.fetchone()
    conn.close()

    if not row:
        return jsonify({"status": "error", "message": "Nie znaleziono użytkownika. Zarejestruj się."}), 404

    stored_hash = row["password_hash"]
    if stored_hash and not check_password_hash(stored_hash, password):
        return jsonify({"status": "error", "message": "Nieprawidłowe hasło"}), 401

    # Brak hasła w bazie (konto utworzone wcześniej, wersja legacy) - przepuść
    return jsonify({"status": "success", "message": "Zalogowano", "user": user_dict(row)})
