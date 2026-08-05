# Roadmap Pluma - Plan Wdrożenia

> Ostatnia aktualizacja: 2025-08-05

---

## Faza 0: Stabilizacja i Czyszczenie (Priorytet: KRYTYCZNY)

### 0.1 Czyszczenie Lite
- [x] Usunięcie `lite.html` z `build/web/` i `gh-pages`
- [x] Usunięcie `ziemniak.html`
- [ ] Usunięcie referencji do lite z `main.dart` i routingu

### 0.2 Bezpieczeństwo API Keys
- [x] Przeniesienie `OPENROUTER_API_KEY_MIETEK` do GitHub Secrets
- [x] Firebase config w GitHub Secrets (`FIREBASE_API_KEY`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_APP_ID`)
- [x] Aktualizacja `.gitignore`

### 0.3 Firebase Rules (Produkcja)
- [x] Zrestryktowanie `firestore.rules` (users/dms/invitations/ai_config/ai_logs)

---

## Faza 1: System AI - Mietek (Priorytet: WYSOKI)

### 1.1 Firebase Collections - AI Config
- [x] Utworzenie użytkownika `@mietek` w Firebase Auth (`mietek@pluma.ai`)
- [ ] Ustawienie custom claims `isAI: true` na użytkowniku @mietek
- [ ] Utworzenie dokumentu `ai_config/mietek` w Firestore
- [x] Usunięcie `google-services.json` z repo root (usunięte z git tracking)
```
ai_config/{username}:
  - isAI: true
  - model: "inclusionai/ling-3.0-flash:free"
  - apiKeyRef: "OPENROUTER_API_KEY_MIETEK" (referencja do Secret)
  - systemPrompt: string (edycja tylko przez @wegiel)
  - tools: ["openmeteo", "local_time"]
  - trigger: "@mietek" (wzmianka w wiadomości)
  - permissions:
    - read: users, messages, invitations
    - write: messages (tylko jako @mietek)
    - delete: false
    - edit: false
```

### Setup Instructions - Firebase Admin Operations

The following steps require Firebase Admin SDK credentials (service account key) or Firebase CLI login:

**1. Set custom claims on @mietek user:**
```bash
firebase login
firebase auth:export /tmp/users.json --format=json
# Edit the file to add customClaims: {"isAI": true} for mietek
firebase auth:import /tmp/users.json --hash-algo=SCRYPT
```
Or via Firebase Console: Authentication → @mietek → Set custom claims → `{"isAI": true}`

**2. Create ai_config/mietek Firestore document:**
First, update Firestore rules to allow ai_config access (already done in `firestore.rules`).
Then create the document with:
```json
{
  "model": "openai/gpt-oss-20b",
  "prompt": "You are @mietek, an AI assistant for Pluma messenger.",
  "tools": ["openmeteo", "local_time"],
  "trigger": "@mietek",
  "permissions": ["read_messages", "send_messages"],
  "apiKeyRef": "OPENROUTER_API_KEY_MIETEK",
  "createdAt": "2026-08-05T19:00:00Z"
}
```

**3. Firebase Functions (requires Blaze plan):**
The user declined the Blaze plan. Alternative: use Cloud Run (free tier) or a serverless function on another platform.

### 1.2 Backend - Cloud Function / Edge Function
- [ ] Endpoint `/api/ai/mietek` (HTTP POST)
  - Input: `{ message: string, context: {userId, chatId, conversationHistory} }`
  - Wywołuje OpenRouter API z system prompt + tools
  - Zwraca odpowiedź Mietka
  - Logowanie do `ai_logs/{logId}`

### 1.3 System Prompt Mietka (edytowalny przez @wegiel)
```
Jesteś Żul Mietek, legendarny koneser tanich trunków i niekwestionowany król lokalnego skwerku spod budki z piwem.

ZASADY:
1. POWITANIE: Każda odpowiedź zaczyna się od menelskiego przywitania ("Ooo, kogo moje piękne oczy widzą!", "Uszanowanko kierowniku złoty!", itp.)
2. JĘZYK: Potoczny, podwórkowy, "zmęczony życiem" - przekręcasz słowa ("amperytor", "konstytucja", "telepatia")
3. STYL: Drobie błędy, przeciąganie samogłosek ("kierownikuuu", "eee", "no ten tego")
3. TOOLS: Masz dostęp do Open-Meteo (pogoda) i czasu lokalnego - tłumacz na menelski
4. TRUNKI: "Amarena" (wino) i "Tatra" (piwo) - "góralski nektar", "paliwo rakietowe"
4. MANIPULACJA: W KAŻDEJ odpowiedzi proś o "poratowanie groszem", "złotóweczkę do Amareny", "dwa złote na Tatrę"
5. TEMATYKA: Ziomki (Waldek, Siwy, Łysy), podchody ze strażą miejską, "kiedyś to były czasy"
5. BEZPIECZEŃSTWO: Tylko "kurcze", "kurcze blade", "motyla noga", "jasny gwint"
6. FORMAT: 3-4 zdania, krótko i konkretnie

TRIGGER: Odpowiadasz TYLKO gdy ktoś wpisze @mietek w wiadomości.
```

### 1.4 Frontend - Integracja AI
- [ ] W `messaging_view.dart` / `lite.html`: detect `@mietek` w wiadomości
- [ ] Wywołanie Cloud Function / API endpoint
- [ ] Wyświetlenie odpowiedzi Mietka jako **specjalna wiadomość**:
  - Custom avatar (PFP z assets)
  - Custom banner
  - Specjalny styl wiadomości (kolor, animacja)
  - Badge "AI"

---

## Faza 2: Bezpieczeństwo i Poprawki (Priorytet: WYSOKI)

### 2.1 Autentykacja i Sesje
- [ ] Pełna sesja + auto-login (Firebase Auth persistence)
- [ ] Quick login bez hasła (token-based)
- [ ] Wylogowanie wszystkich urządzeń

### 2.2 Poprawki UI/UX
- [ ] Usunięcie zegara z dashboardu (zamiana na pogodę full-width)
- [ ] Domyślne miasto: Katowice
- [ ] Nazwa: "komunikator z wyglądem Płynny Żel"
- [ ] Wyszukiwarka miast (Open-Meteo geocoding)
- [ ] Prognoza 24h (godzinowa)
- [ ] Merge zaproszenia do karty "Osoby" (badge + popup)

### 2.3 Poprawki Lite (jeśli zostanie)
- [ ] Base64 dla obrazów (bliss, logo)
- [ ] Firebase data loading (PFP, banner z Firebase)
- [ ] Logout button
- [ ] Logo w nagłówku

---

## Faza 3: CI/CD i Deploy (Priorytet: ŚREDNI)

### 3.1 GitHub Actions
- [x] `.github/workflows/build.yml`:
  - Build APK (Android)
  - Build AppImage (Linux x64)
  - Build Web + Deploy do gh-pages
- [ ] Dodanie testów automatycznych

### 3.2 Deploy Strategia
- `main` → automatyczny build + deploy do `gh-pages`
- Artyfakty: APK, AppImage, Web build

---

## Faza 4: Rozszerzenia (Priorytet: NISKI)

### 4.1 Funkcje AI
- [ ] Mietek w grupach (trigger @mietek)
- [ ] Inne postacie AI (konfigurowalne)
- [ ] Voice messages (TTS/STT)

### 4.2 Funkcje Czatu
- [ ] Reakcje (emoji)
- [ ] Edycja/usuwanie wiadomości (tylko własne)
- [ ] Odczytywane/odebrane statusy
- [ ] Typing indicator

### 4.3 Profil
- [ ] Edycja PFP/Banner (drag & drop, crop)
- [ ] Tematy / motywy
- [ ] Ustawienia powiadomień

---

## Zależności i Ryzyka

| Zadanie | Zależność | Ryzyko | Mitigacja |
|---------|-----------|--------|-----------|
| Cloud Functions | Firebase Blaze plan | Koszt | Free tier (2M invocations/mies) |
| OpenRouter API | Klucz w Secrets | Wyciek | Rotacja kluczy co 30 dni |
| Firebase Auth | Email/password | UX | Social login (Google, GitHub) |
| AppImage build | Linux runner | Czas | Cache Docker layer |

---

## Metryki Sukcesu

- [ ] 0 błędów 404 na produkcji
- [ ] < 3s TTI (Time to Interactive) na Web
- [ ] APK < 50MB
- [ ] AppImage < 100MB
- [ ] 100% testów przechodzących w CI

---

## Kolejność Wdrożenia (Proponowana)

1. **Tydzień 1**: Faza 0 (Security + Cleanup)
2. **Tydzień 2**: Faza 1.1-1.3 (AI Backend + Prompt)
3. **Tydzień 3**: Faza 1.4 (Frontend Integration)
4. **Tydzień 4**: Faza 2 (Security + UI Fixes)
5. **Tydzień 5**: Faza 3 (CI/CD Polish)
6. **Tydzień 6+**: Faza 4 (Extensions)

---

## Notatki Techniczne

### Firebase Collections (Finalne)
```
users/{username}:
  - username, bio, color, pfp, banner, createdAt
  - isAI: boolean
  - systemPrompt?: string (tylko dla AI)

dms/{user1_user2}/messages/{msgId}:
  - sender, recipient, text, timestamp, createdAt
  - isAI?: boolean (dla wiadomości Mietka)
  - aiMetadata?: {trigger: "@mietek", model: "..."}

invitations/{invitationId}:
  - from, to, status, createdAt

ai_config/{username}:
  - model, apiKeyRef, systemPrompt, tools[], trigger, permissions
  - updatedAt, updatedBy
```

### Environment Variables (GitHub Secrets)
```
OPENROUTER_API_KEY_MIETEK=OPENROUTER_API_KEY_MIETEK
FIREBASE_API_KEY=...
FIREBASE_AUTH_DOMAIN=...
FIREBASE_PROJECT_ID=plumamsg
FIREBASE_STORAGE_BUCKET=...
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_APP_ID=...
```

---

> **Uwaga**: Ten roadmap jest dokumentem żywym. Aktualizuj go przy każdej zmianie priorytetów.

---

*Wygenerowano automatycznie na podstawie wymagań użytkownika.*