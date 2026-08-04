import os
import sqlite3
import time

DB_FILE = os.path.join(os.path.dirname(__file__), "pluma.db")

def get_db_connection():
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    return conn

def _column_exists(cursor, table, column):
    cursor.execute(f"PRAGMA table_info({table})")
    cols = [row[1] for row in cursor.fetchall()]
    return column in cols

def init_db():
    """Tworzenie i migracja tabel w bazie SQLite przy uruchomieniu"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Tabela wiadomości
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                sender TEXT NOT NULL,
                recipient TEXT NOT NULL,
                text TEXT,
                imageUrl TEXT,
                videoUrl TEXT,
                createdAt INTEGER NOT NULL,
                timestamp TEXT NOT NULL
            )
        ''')

        # Tabela profili użytkowników (z hasłem)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                username TEXT PRIMARY KEY,
                bio TEXT,
                pfp TEXT,
                banner TEXT,
                color TEXT,
                createdAt INTEGER,
                password_hash TEXT
            )
        ''')

        # Bezpieczna migracja: dodaj kolumnę password_hash, jeśli jej brakuje
        if not _column_exists(cursor, 'users', 'password_hash'):
            cursor.execute('ALTER TABLE users ADD COLUMN password_hash TEXT')

        conn.commit()
        conn.close()
    except Exception as e:
        print(f"Inicjalizacja bazy SQLite zwróciła wyjątek (bezpieczne wbudowanie): {e}")
