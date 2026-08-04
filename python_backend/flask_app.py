# PythonAnywhere WSGI Entry Point
# W PythonAnywhere domyślna nazwa zmiennej aplikacji to 'application' w pliku 'flask_app.py'

import os
import sys

# Dodaj bieżący katalog do ścieżki sys.path
sys.path.insert(0, os.path.dirname(__file__))

from flask import Flask, render_template_string, send_from_directory
try:
    from flask_cors import CORS
    HAS_CORS = True
except ImportError:
    HAS_CORS = False

from database import init_db
from auth import auth_bp
from messages import messages_bp
from users import users_bp
from weather import weather_bp

app = Flask(__name__, static_folder='.', static_url_path='')

if HAS_CORS:
    CORS(app)

# Inicjalizacja bazy SQLite (pluma.db)
init_db()

# Rejestracja modułów/blueprintów
app.register_blueprint(auth_bp, url_prefix='/api')
app.register_blueprint(messages_bp, url_prefix='/api')
app.register_blueprint(users_bp, url_prefix='/api')
app.register_blueprint(weather_bp, url_prefix='/api')

@app.route('/static/<path:filename>')
def serve_static(filename):
    return send_from_directory('.', filename)

@app.route('/favicon.ico')
def favicon():
    return send_from_directory('.', 'logo.ico', mimetype='image/x-icon')

@app.route('/')
def home():
    return render_template_string("""
    <!DOCTYPE html>
    <html lang="pl">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <title>Pluma Liquid Glass - Flask Web Server</title>
        <link rel="icon" href="/favicon.ico" type="image/x-icon">
        <link rel="stylesheet" href="/style.css">
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            html, body {
                width: 100%;
                min-height: 100vh;
                background: #061700;
                color: #ffb870;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                padding: 16px;
                overflow-x: hidden;
            }
            .glass-card {
                background: rgba(255, 255, 255, 0.05);
                backdrop-filter: blur(20px);
                -webkit-backdrop-filter: blur(20px);
                border: 1px solid rgba(255, 255, 255, 0.12);
                border-radius: 24px;
                padding: 32px;
                max-width: 680px;
                width: 100%;
                box-shadow: 0 20px 50px rgba(0,0,0,0.6);
            }
            h1 { color: #ffffff; font-size: 24px; margin-bottom: 8px; display: flex; align-items: center; gap: 10px; word-break: break-word; }
            p { color: #c2c9bd; font-size: 14px; margin-bottom: 20px; line-height: 1.5; }
            .badge {
                display: inline-flex;
                align-items: center;
                gap: 6px;
                background: rgba(74, 222, 128, 0.15);
                color: #4ade80;
                border: 1px solid rgba(74, 222, 128, 0.3);
                padding: 4px 12px;
                border-radius: 999px;
                font-size: 11px;
                font-family: monospace;
                margin-bottom: 20px;
            }
            .endpoint-grid {
                display: grid;
                grid-template-cols: 1fr;
                gap: 10px;
                margin-top: 12px;
            }
            .endpoint-item {
                background: rgba(0,0,0,0.35);
                border: 1px solid rgba(255,255,255,0.08);
                border-radius: 14px;
                padding: 14px 16px;
                display: flex;
                justify-content: space-between;
                align-items: center;
                font-family: monospace;
                font-size: 13px;
                flex-wrap: wrap;
                gap: 8px;
            }
            .method { color: #ffb870; font-weight: bold; }
            a { color: #82da6a; text-decoration: none; word-break: break-all; }
            a:hover { text-decoration: underline; }
            .footer { margin-top: 24px; text-align: center; font-size: 11px; color: #888; font-family: monospace; line-height: 1.4; }

            @media (max-width: 600px) {
                body { padding: 12px; }
                .glass-card { padding: 20px 16px; border-radius: 18px; }
                h1 { font-size: 20px; }
                p { font-size: 13px; }
                .endpoint-item { flex-direction: column; align-items: flex-start; gap: 4px; }
            }
        </style>
    </head>
    <body>
        <div class="glass-card">
            <span class="badge">● AKTYWNY BACKEND FLASK (PYTHONANYWHERE)</span>
            <h1>Pluma Liquid Glass Server</h1>
            <p>Serwer Flask działający z pełną bazą SQLite bez limitów transferu i zapisów. Pełne API dla wiadomości, profili użytkowników i pogody z obsługą urządzeń mobilnych oraz stacjonarnych.</p>
            
            <h3 style="color: #fff; font-size: 14px; margin-bottom: 8px; font-family: monospace;">Dostępne Endpointy API:</h3>
            <div class="endpoint-grid">
                <div class="endpoint-item">
                    <span><span class="method">GET</span> /api/messages</span>
                    <a href="/api/messages" target="_blank">Otwórz &rarr;</a>
                </div>
                <div class="endpoint-item">
                    <span><span class="method">POST</span> /api/messages</span>
                    <span style="color: #aaa;">(wysyłanie wiadomości)</span>
                </div>
                <div class="endpoint-item">
                    <span><span class="method">GET</span> /api/users</span>
                    <a href="/api/users" target="_blank">Otwórz &rarr;</a>
                </div>
                <div class="endpoint-item">
                    <span><span class="method">GET</span> /api/weather</span>
                    <a href="/api/weather" target="_blank">Otwórz &rarr;</a>
                </div>
            </div>

            <div class="footer">
                Dla PythonAnywhere: w sekcji Web ustaw WSGI file tak, by importował 'application' z 'flask_app'.
            </div>
        </div>
    </body>
    </html>
    """)

# Wymagany alias dla PythonAnywhere WSGI (application = app)
application = app

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
