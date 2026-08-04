=== PLUMA FLASK — URUCHOMIENIE LOKALNE DO TESTÓW ===

Wymagane: Python 3.10+ na Windows.

1) Zainstaluj zależności (w folderze python_backend):
   pip install -r requirements.txt

2) Uruchom serwer:
   python flask_app.py
   -> Serwer wystartuje pod http://localhost:5000

3) Strona powitalna + ikona:
   http://localhost:5000          -> dashboard serwera (favicon = logo.ico)
   http://localhost:5000/favicon.ico
   http://localhost:5000/api/users
   http://localhost:5000/api/messages

=== WSPÓŁPRACA Z APLIKACJĄ WINDOWS (pluma.exe) ===

Aplikacja desktopowa domyślnie łączy się z http://localhost:5000/api.
Uruchom serwer, a potem odpal pluma.exe — gotowe.

JEŚLI backend jest pod innym adresem, przebuduj apkę z innym URL:
   flutter build windows --release --dart-define=API_BASE_URL=http://ADRESS:PORT/api

=== GITHUB PAGES (flutter build web) ===

Aplikacja webowa (build/web) wysyła żądania CORS do API Flaska.
Domyślnie cel to http://localhost:5000/api. Dla wdrożenia wgraj build/web
na GitHub Pages i przebuduj z docelowym adresem backendu:

   flutter build web --release --dart-define=API_BASE_URL=https://TWOJA-NAZWA.pythonanywhere.com/api

WAŻNE: Flask ma włączony CORS(app) w flask_app.py, więc żądania z domeny
GitHub Pages są dozwolone. Hasła są hashowane Werkzeug (auth.py), baza to
SQLite (pluma.db).

=== NOTATKA ===
Flask NIE serwuje folderu build/web automatycznie — to osobny host (GitHub
Pages). Flask obsługuje tylko API (i starszą aplikację webową w src/, gdy
została zbudowana do tego samego folderu).
