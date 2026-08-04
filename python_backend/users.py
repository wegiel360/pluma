import time
from flask import Blueprint, request, jsonify
from database import get_db_connection

users_bp = Blueprint('users', __name__)

@users_bp.route("/users", methods=["GET"])
def get_users():
    """Pobiera listę użytkowników"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users")
        rows = cursor.fetchall()
        conn.close()
        
        users = [dict(row) for row in rows]
        return jsonify({"status": "success", "users": users})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@users_bp.route("/users/<username>", methods=["GET"])
def get_user_profile(username):
    """Pobiera konkretny profil"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
        row = cursor.fetchone()
        conn.close()
        
        if not row:
            return jsonify({"status": "error", "message": "Nie znaleziono użytkownika"}), 404
            
        return jsonify({"status": "success", "user": dict(row)})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@users_bp.route("/users/<username>", methods=["PUT", "POST"])
def update_user_profile(username):
    """Zapisuje lub aktualizuje profil w SQLite"""
    try:
        data = request.json or {}
        bio = data.get("bio")
        pfp = data.get("pfp")
        banner = data.get("banner")
        color = data.get("color")
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE username = ?", (username,))
        existing = cursor.fetchone()
        
        now = int(time.time() * 1000)
        
        if existing:
            new_bio = bio if bio is not None else existing["bio"]
            new_pfp = pfp if pfp is not None else existing["pfp"]
            new_banner = banner if banner is not None else existing["banner"]
            new_color = color if color is not None else existing["color"]
            
            cursor.execute("""
                UPDATE users SET bio = ?, pfp = ?, banner = ?, color = ? WHERE username = ?
            """, (new_bio, new_pfp, new_banner, new_color, username))
        else:
            cursor.execute("""
                INSERT INTO users (username, bio, pfp, banner, color, createdAt)
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                username, 
                bio or "", 
                pfp or "", 
                banner or "", 
                color or "#ffb870", 
                now
            ))
            
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Profil zaktualizowany"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500
