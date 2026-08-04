import os
import re
import time

DATABASE_URL = os.environ.get("DATABASE_URL", "")

# ---------------------------------------------------------------------------
# PostgreSQL (gdy DATABASE_URL jest ustawione) lub SQLite (fallback lokalny)
# ---------------------------------------------------------------------------

def _is_postgres():
    return DATABASE_URL.startswith("postgresql") or DATABASE_URL.startswith("postgres")


# ---------------------------------------------------------------------------
# Warstwa kompatybilności: zamienia ? na %s dla psycopg2,
# zwraca kursor z dostępem row["col"] jak w sqlite3.Row.
# ---------------------------------------------------------------------------

class _PgCursor:
    """Wrapper nad psycopg2 cursorem — tłumaczy ? → %s i zwraca dicty."""

    def __init__(self, real_cursor):
        self._cur = real_cursor

    # sqlite3.Row pozwala row["col"], psycopg2 row jest tuple.
    # RealDictCursor z extras daje dict, ale dodajemy RowDict jako backup.
    def _to_row(self, row):
        if row is None:
            return None
        if isinstance(row, dict):
            return row
        # fallback: zamień tuple na dict z nazwami kolumn
        cols = [d[0] for d in self._cur.description]
        return dict(zip(cols, row))

    def _convert_query(self, query):
        """Zamienia ? na %s w zapytaniu SQL."""
        return re.sub(r"\?", "%s", query)

    def execute(self, query, params=None):
        converted = self._convert_query(query)
        if params is None:
            self._cur.execute(converted)
        else:
            self._cur.execute(converted, params)

    def fetchone(self):
        return self._to_row(self._cur.fetchone())

    def fetchall(self):
        return [self._to_row(r) for r in self._cur.fetchall()]

    def __getattr__(self, name):
        return getattr(self._cur, name)


class _PgConnection:
    """Wrapper nad psycopg2 connection — zwraca _PgCursor."""

    def __init__(self, real_conn):
        self._conn = real_conn

    def cursor(self):
        return _PgCursor(self._conn.cursor())

    def commit(self):
        self._conn.commit()

    def close(self):
        self._conn.close()

    def __getattr__(self, name):
        return getattr(self._conn, name)


# ---------------------------------------------------------------------------
# get_db_connection — główny punkt wejścia dla wszystkich blueprintów
# ---------------------------------------------------------------------------

def get_db_connection():
    if _is_postgres():
        import psycopg2
        import psycopg2.extras
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = False
        # RealDictCursor zwraca dict zamiast tuple
        return _PgConnection(conn)
    else:
        import sqlite3
        db_file = os.path.join(os.path.dirname(__file__), "pluma.db")
        conn = sqlite3.connect(db_file)
        conn.row_factory = sqlite3.Row
        return conn


# ---------------------------------------------------------------------------
# init_db — tworzenie tabel. SQLite i PostgreSQL mają różne składnie.
# Wywoływane raz przy starcie serwera.
# ---------------------------------------------------------------------------

def init_db():
    if _is_postgres():
        _init_pg()
    else:
        _init_sqlite()


def _init_pg():
    """Inicjalizacja bazy PostgreSQL (Render)."""
    try:
        import psycopg2
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cursor = conn.cursor()

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS messages (
                id TEXT PRIMARY KEY,
                sender TEXT NOT NULL,
                recipient TEXT NOT NULL,
                text TEXT,
                imageUrl TEXT,
                videoUrl TEXT,
                createdAt BIGINT NOT NULL,
                timestamp TEXT NOT NULL
            )
        ''')

        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                username TEXT PRIMARY KEY,
                bio TEXT,
                pfp TEXT,
                banner TEXT,
                color TEXT,
                createdAt BIGINT,
                password_hash TEXT
            )
        ''')

        conn.close()
        print("Baza PostgreSQL zainicjalizowana pomyślnie.")
    except Exception as e:
        print(f"Inicjalizacja PostgreSQL zwróciła wyjątek: {e}")


def _init_sqlite():
    """Inicjalizacja lokalnej bazy SQLite (debugging)."""
    import sqlite3
    db_file = os.path.join(os.path.dirname(__file__), "pluma.db")
    try:
        conn = sqlite3.connect(db_file)
        cursor = conn.cursor()

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

        if not _column_exists(cursor, 'users', 'password_hash'):
            cursor.execute('ALTER TABLE users ADD COLUMN password_hash TEXT')

        conn.commit()
        conn.close()
    except Exception as e:
        print(f"Inicjalizacja bazy SQLite zwróciła wyjątek: {e}")


def _column_exists(cursor, table, column):
    cursor.execute(f"PRAGMA table_info({table})")
    cols = [row[1] for row in cursor.fetchall()]
    return column in cols
