# Pluma

<div align="center">
<img src="PlumaFlutter/assets/logo-pluma.png" alt="Pluma Logo" width="160" />
<br/><br/>
Flutter · Firebase · GitHub Pages · GitHub Actions
</div>

## O projekcie

**Pluma** to komunikator z wyglądem **Płynny Żel** — półprzezroczyste panele,
pastelowa paleta, delikatne irydescencyjne obramowania.

Aplikacja działa na **Web**, **Android** (APK) oraz **Linux** (AppImage).

**Linki:**
- [Wersja pełna (Flutter)](https://wegiel360.github.io/pluma/)
- [Wersja Lite (HTML/CSS/JS)](https://wegiel360.github.io/pluma/lite.html)

---

## Funkcje

- **Autoryzacja** — logowanie bez emaila (nickname + hasło)
- **Wiadomości** — DM między znajomymi (wspólna baza Firebase)
- **Zaproszenia** — system zaproszeń do znajomych
- **Profile** — avatar (PFP), baner, kolor, bio (zapisane w Firebase)
- **Pogoda** — Open-Meteo API, wyszukiwarka miast, prognoza 24h
- **Auto-login** — sesja zapamiętywana po odświeżeniu strony

---

## Wersje

| Wersja | Technologia | Target |
|--------|-------------|--------|
| **Pełna** | Flutter Web + Firebase | Nowoczesne przeglądarki |
| **Lite** | HTML5 + CSS3 + JS + Firebase | Firefox 52.9+, IE11 (częściowo) |
| **Android** | Flutter APK | Android 5.0+ |
| **Linux** | Flutter + AppImage | Linux x64 |

---

## Struktura repozytorium

```
pluma/
├── .github/workflows/       # CI/CD
│   └── build.yml            # Build APK + AppImage + Web deploy
├── PlumaFlutter/            # Aplikacja Flutter
│   ├── lib/
│   │   ├── api/             # Firebase/Firedart API layer
│   │   ├── screens/         # Ekrany (login, dashboard, messaging, profile)
│   │   └── theme/           # Motyw Płynny Żel
│   ├── assets/              # Loga, obrazy, fonty
│   ├── web/                 # Web config + lite.html
│   └── firebase_options.dart
├── docs/                    # Dokumentacja
└── README.md
```

---

## Firebase

**Kolekcje:**
- `users/{username}` — profile użytkowników
- `dms/{user1_user2}/messages/{msgId}` — wiadomości direct
- `invitations/{invitationId}` — zaproszenia

**Bezpieczeństwo:**
- Reguły Firestore: `allow read, write: if true;` (dev)
- Hasła przechywane w Firebase (nie w localStorage)

---

## Budowanie lokalnie

```bash
cd PlumaFlutter
flutter pub get

# Web
flutter build web --release --base-href "/pluma/"

# Android
flutter build apk --release

# Linux
flutter config --enable-linux-desktop
flutter build linux --release
```

## GitHub Actions

Workflow automatycznie buduje:
- **APK** (Android)
- **AppImage** (Linux x64)
- **Web** + deploy na GitHub Pages

Trigger: push do `main` lub ręcznie (`workflow_dispatch`).

---

## Licencja

Projekt prywatny. Wszelkie prawa zastrzeżone.
