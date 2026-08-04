import time
from flask import Blueprint, request, jsonify
from database import get_db_connection

messages_bp = Blueprint('messages', __name__)

@messages_bp.route("/messages", methods=["GET"])
def get_all_messages():
    """Pobiera wszystkie wiadomości z bazy"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM messages ORDER BY createdAt ASC")
        rows = cursor.fetchall()
        conn.close()
        
        messages = [dict(row) for row in rows]
        return jsonify({"status": "success", "messages": messages})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@messages_bp.route("/messages/<user1>/<user2>", methods=["GET"])
def get_conversation(user1, user2):
    """Pobiera rozmowę dwóch użytkowników"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM messages 
            WHERE (sender = ? AND recipient = ?) OR (sender = ? AND recipient = ?)
            ORDER BY createdAt ASC
        """, (user1, user2, user2, user1))
        rows = cursor.fetchall()
        conn.close()
        
        messages = [dict(row) for row in rows]
        return jsonify({"status": "success", "messages": messages})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@messages_bp.route("/messages", methods=["POST"])
def send_message():
    """Wysyła i zapisuje nową wiadomość bez limitów"""
    try:
        data = request.json or {}
        sender = data.get("sender")
        recipient = data.get("recipient") or data.get("receiver")
        text = data.get("text", "")
        imageUrl = data.get("imageUrl")
        videoUrl = data.get("videoUrl")
        
        if not sender or not recipient:
            return jsonify({"status": "error", "message": "Brak nadawcy lub odbiorcy"}), 400
            
        msg_id = f"msg_{int(time.time() * 1000)}"
        created_at = int(time.time() * 1000)
        timestamp_str = time.strftime("%H:%M")
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO messages (id, sender, recipient, text, imageUrl, videoUrl, createdAt, timestamp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (msg_id, sender, recipient, text, imageUrl, videoUrl, created_at, timestamp_str))
        conn.commit()
        conn.close()
        
        return jsonify({
            "status": "success",
            "message": {
                "id": msg_id,
                "sender": sender,
                "recipient": recipient,
                "text": text,
                "imageUrl": imageUrl,
                "videoUrl": videoUrl,
                "createdAt": created_at,
                "timestamp": timestamp_str
            }
        }), 201
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@messages_bp.route("/messages/<msg_id>", methods=["DELETE"])
def delete_message(msg_id):
    """Usuwa pojedynczą wiadomość po ID"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM messages WHERE id = ?", (msg_id,))
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Wiadomość usunięta"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@messages_bp.route("/messages", methods=["DELETE"])
def delete_all_messages():
    """Usuwa wszystkie wiadomości z bazy"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM messages")
        conn.commit()
        conn.close()
        return jsonify({"status": "success", "message": "Wszystkie wiadomości usunięte"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

