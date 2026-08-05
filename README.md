# <b>Pluma<b>
<div align="center">
<img src="PlumaFlutter/assets/logo-pluma.png" alt="Pluma Logo" width="160" />
<br/><br/>
Flutter · GH Pages · Firebase
</div>

## O projekcie

**Pluma** to komunikator zintegrowany z pulpitem, napisany w **Flutter**.

Interfejs wyróżnia estetyka **Płynny Żel** — półprzezroczyste panele ze
szkłem rozmytym, pastelowa paleta oraz delikatne, irydescencyjne obramowania.
Aplikacja działa na **Windows**, **Android** oraz w **przeglądarce** (Web / GitHub Pages).

---

## Funkcje

- **Autoryzacja** — rejestracja i logowanie z hashowaniem haseł (Werkzeug).
- **Wiadomości** — wysyłanie, edycja, usuwanie i podgląd konwersacji w czasie rzeczywistym (polling).
- **Profile** — dostosowywanie avatara, banera, koloru akcentu i opisu.
- **Pogoda** — panel pogodowy pobierany z zewnętrznego API OpenMeteo.
- **Konta lokalne** — zapamiętywanie zapisanych kont na urządzeniu.
- **Motywy** — płynny żel (glassmorphism), spójna paleta kolorów Płynny Żel.

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

## Frontend - aplikacja Flutter

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

> Bezpieczeństwo: hasła są przechowywane jako skróty **Werkzeug** — nigdy w postaci jawnej.

## Licencja

Projekt prywatny. Wszelkie prawa zastrzeżone.
