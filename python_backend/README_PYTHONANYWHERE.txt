========================================================================
 INSTRUKCJA JAK NAPRAWIĆ "Unhandled Exception" NA PYTHONANYWHERE.COM
========================================================================

------------------------------------------------------------------------
KROK 1: WGRAJ PLIKI
------------------------------------------------------------------------
1. Zaloguj się na https://www.pythonanywhere.com/
2. W zakładce "Files" wgraj pliki bezpośrednio w katalogu `/home/wegiel`:
   - flask_app.py
   - database.py
   - messages.py
   - users.py
   - weather.py
   - wsgi.py
   - requirements.txt
   - style.css
   - logo.ico

------------------------------------------------------------------------
KROK 2: ZAINSTALUJ WYMAGANE PACZKI W CONSOLE (BASH)
------------------------------------------------------------------------
1. Otwórz zakładkę "Consoles" -> "Bash".
2. Wykonaj polecenie instalacji bibliotek:
   pip install --user flask flask-cors requests

------------------------------------------------------------------------
KROK 3: SKONFIGURUJ ZAKŁADKĘ "WEB" ORAZ PLIK WSGI
------------------------------------------------------------------------
1. Przejdź do zakładki "Web" na PythonAnywhere.
2. Kliknij na link w sekcji **"Code:"** -> **"WSGI configuration file"**
   (np. `/var/www/wegiel_pythonanywhere_com_wsgi.py`).
3. Wyczyszcz całą zawartość tego pliku i wklej następujące linie:

```python
import sys
import os

path = '/home/wegiel'
if path not in sys.path:
    sys.path.insert(0, path)

from flask_app import app as application
```

------------------------------------------------------------------------
KROK 4: RESTART APLIKACJI
------------------------------------------------------------------------
1. Wróć do zakładki "Web".
2. Kliknij zielony przycisk **"Reload wegiel.pythonanywhere.com"**.
3. Twoja strona i API są gotowe!

