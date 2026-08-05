# Pluma

<div align="center">
<img src="PlumaFlutter/assets/logo-pluma.png" alt="Pluma Logo" width="160" />
<br/><br/>
<b>Nowoczesny komunikator w stylu Płynny Żel.</b><br/>
Flutter · Flask API · SQLite
</div>

---

## Spis treści

- [O projekcie](#o-projekcie)
- [Funkcje](#funkcje)
- [Struktura repozytorium](#struktura-repozytorium)
- [Frontend — aplikacja Flutter](#frontend--aplikacja-flutter)
- [Backend — API Flask](#backend--api-flask)
- [Hosting & wdrożenie](#hosting--wdrożenie)
- [Rozwój lokalny](#rozwój-lokalny)

---

## O projekcie

**Pluma** to komunikator (messenger) zintegrowany z pulpitem (dashboard),
napisany w **Flutter**.

Interfejs wyróżnia estetyka **Płynny Żel** — półprzezroczyste panele ze
szkłem rozmytym, pastelowa paleta oraz delikatne, irydescencyjne obramowania.
Aplikacja działa na **Windows**, **Android** oraz w **przeglądarce** (Web / GitHub Pages).

---

## Funkcje

- **Autoryzacja** — rejestracja i logowanie z hashowaniem haseł (Werkzeug).
- **Wiadomości** — wysyłanie, edycja, usuwanie i podgląd konwersacji w czasie rzeczywistym (polling).
- **Profile** — dostosowywanie avatara, banera, koloru akcentu i opisu.
- **Pogoda** — panel pogodowy pobierany z zewnętrznego API.
- **Konta lokalne** — zapamiętywanie zapisanych kont na urządzeniu.
- **Motywy** — płynne szkło (glassmorphism), spójna paleta kolorów Liquid Glass.

---

## Struktura repozytorium

```
pluma/
├── PlumaFlutter/          # Frontend — aplikacja Flutter (Windows/Android/Web)
│   ├── lib/
│   │   ├── api/           # Warstwa danych (klient HTTP, modele)
│   │   ├── theme/         # Motyw Liquid Glass i komponenty Glass
│   │   └── screens/       # Ekrany (login, dashboard, messaging, profile)
│   ├── assets/            # Loga, obrazy, tła
│   └── test/              # Testy Flutter
├── python_backend/        # Backend — API Flask (SQLite)
│   ├── flask_app.py       # Główna aplikacja Flask (CORS, blueprinty)
│   ├── auth.py            # Rejestracja / logowanie (Werkzeug)
│   ├── messages.py        # Wiadomości
│   ├── users.py           # Profile użytkowników
│   ├── weather.py         # Pogoda
│   └── database.py        # Baza SQLite + migracje
└── docs/                  # Dokumentacja pomocnicza
```

---

## Frontend — aplikacja Flutter

### Wymagania

- Flutter 3.x (Dart 3.x)
- Dla Windows: Visual Studio z komponentem "Desktop development with C++"
- Dla Androida: Android SDK + JDK

### Budowanie aplikacji

```bash
cd PlumaFlutter
flutter pub get

# Windows (desktop)
flutter build windows --release

# Android (APK)
flutter build apk --release

# Web (produkcja, np. GitHub Pages)
flutter build web --release --base-href "/pluma/" --dart-define=API_BASE_URL=<URL_API>
```

### Konfiguracja adresu API

Bazowy adres backendu wstrzykuje się w czasie budowania przez zmienną `API_BASE_URL`
(domyślnie `http://localhost:5000/api`). Frontend wysyła **żądania CORS** do wskazanego
adresu i nigdy nie szuka plików po stronie backendu.

```bash
flutter build windows --release --dart-define=API_BASE_URL=https://api.example.com/api
```

---

## Backend — API Flask

### Uruchomienie lokalne

```bash
cd python_backend
pip install -r requirements.txt
python flask_app.py
```

Serwer wstaje na `http://localhost:5000`. Baza SQLite (`pluma.db`) tworzy się
automatycznie przy starcie (z migracją `password_hash`).

### Główne endpointy (`/api`)

| Metoda | Ścieżka              | Opis                        |
|--------|----------------------|-----------------------------|
| POST   | `/auth/register`     | Rejestracja użytkownika     |
| POST   | `/auth/login`        | Logowanie                   |
| GET    | `/users`             | Lista użytkowników          |
| GET/POST | `/users/<username>` | Pobierz / utwórz / zaktualizuj profil |
| GET    | `/messages`          | Wszystkie wiadomości        |
| POST   | `/messages`          | Wyślij wiadomość            |
| DELETE | `/messages/<id>`     | Usuń wiadomość              |
| GET    | `/weather`           | Dane pogodowe               |

> Bezpieczeństwo: hasła są przechowywane jako skróty **Werkzeug** — nigdy w postaci jawnej.

---

## Hosting & wdrożenie

- **Frontend (Web)** — build z `PlumaFlutter/build/web` wgrywany na **GitHub Pages**
  (gałąź `gh-pages`), pod adresem repo `wegiel360/pluma`.
- **Backend (API)** — Flask na zewnętrznym hostingu API (np. **Render**, **Railway**).
  Frontend na GitHub Pages wskazuje na adres tego API przez `--dart-define=API_BASE_URL`.
- **CORS** — w `flask_app.py` aktywny `CORS(app)`, więc żądania z domeny GitHub Pages są dozwolone.

---

## Rozwój lokalny

1. Uruchom backend:
   ```bash
   cd python_backend && python flask_app.py
   ```
2. Uruchom apkę Flutter na Windows:
   ```bash
   cd PlumaFlutter && flutter run -d windows
   ```
   (backend dostępny pod `http://localhost:5000/api`).

---

## Licencja

Projekt prywatny. Wszelkie prawa zastrzeżone.
