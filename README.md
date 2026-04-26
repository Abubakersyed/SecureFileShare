# SecureFileShare

A privacy-first file sharing and remote printing system.

- AES-256 encryption on every file
- RAM-only storage — files never touch disk
- Auto-delete on download or TTL expiry (5 / 15 / 30 mins)
- JWT authentication for senders
- QR code / session token for recipients
- Flutter mobile app (Android + iOS)
- Simple HTML/CSS/JS web frontend for print shops

---

## Project Structure

```
SecureFileShare/
├── backend/
│   ├── app/
│   │   ├── main.py                  ← FastAPI entry point
│   │   ├── models/
│   │   │   └── database.py          ← SQLite/PostgreSQL models (metadata only)
│   │   ├── routers/
│   │   │   ├── auth.py              ← /auth/register, /auth/login
│   │   │   └── files.py             ← /files/upload, /files/info, /files/download
│   │   └── services/
│   │       ├── memory_store.py      ← RAM-only file storage
│   │       ├── encryption.py        ← AES-256 encrypt/decrypt
│   │       ├── auth.py              ← JWT + bcrypt
│   │       ├── scheduler.py         ← TTL auto-delete background job
│   │       └── qr_service.py        ← QR code generator
│   ├── requirements.txt
│   ├── .env
│   └── run.py                       ← Start the server
├── frontend/
│   └── index.html                   ← Print shop access page
└── mobile/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart                ← App entry point
        ├── screens/
        │   ├── login_screen.dart    ← Login / Register UI
        │   ├── home_screen.dart     ← File picker + upload
        │   └── qr_screen.dart       ← QR code display after upload
        └── services/
            └── api_service.dart     ← HTTP calls to backend
```

---

## SETUP GUIDE

### Step 1 — Backend Setup

**Requirements:** Python 3.10 or higher

Open PowerShell or Command Prompt and run:

```bash
cd SecureFileShare/backend

# Create a virtual environment (keeps packages isolated)
python -m venv venv

# Activate it (Windows)
venv\Scripts\activate

# Install all dependencies
pip install -r requirements.txt

# Start the server
python run.py
```

The backend will start at: http://localhost:8000

You can view the interactive API docs at: http://localhost:8000/docs

---

### Step 2 — Frontend Setup

No setup needed — it's plain HTML.

While the backend is running, open your browser and go to:

```
http://localhost:8000/access/YOUR_SESSION_TOKEN
```

Or just open `frontend/index.html` directly in a browser for testing.

---

### Step 3 — Flutter App Setup

**Requirements:** Flutter SDK installed (https://flutter.dev/docs/get-started/install)

```bash
cd SecureFileShare/mobile

# Download all Flutter packages
flutter pub get

# Run on Android emulator
flutter run

# Build APK for Android
flutter build apk --release

# Build for iOS (requires macOS + Xcode)
flutter build ios --release
```

**Important:** If testing on a real Android device (not emulator), change the
BASE_URL in `lib/services/api_service.dart` from:

```dart
const String BASE_URL = "http://10.0.2.2:8000";
```

To your computer's local IP address, e.g.:

```dart
const String BASE_URL = "http://192.168.1.5:8000";
```

Find your IP by running `ipconfig` in Command Prompt and looking for IPv4 Address.

---

## API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /auth/register | None | Create sender account |
| POST | /auth/login | None | Login, get JWT token |
| POST | /files/upload | JWT | Upload + encrypt file |
| GET | /files/info/{id} | None | Get session metadata |
| GET | /files/download/{id} | None | Download + delete file |
| DELETE | /files/cancel/{id} | JWT | Cancel and delete session |

---

## How It Works

```
SENDER (Flutter App)
  │
  ├─ Logs in → receives JWT token
  ├─ Picks a file from app sandbox
  ├─ Chooses TTL: 5 / 15 / 30 mins
  └─ File is AES-256 encrypted → sent over HTTPS to backend

BACKEND (FastAPI)
  │
  ├─ Receives encrypted file bytes
  ├─ Stores ONLY in RAM (Python dict) — never written to disk
  ├─ Saves metadata (session ID, expiry, filename) to SQLite
  ├─ Generates QR code + session token
  └─ Returns QR + token to Flutter app

RECIPIENT (Print Shop Web Page)
  │
  ├─ Opens http://localhost:8000/access/<token>
  ├─ Views file metadata + countdown timer
  ├─ Clicks Download & Print
  └─ File is decrypted → sent → IMMEDIATELY deleted from RAM

AUTO-DELETE (Background Scheduler)
  └─ Runs every 60 seconds
     └─ Any session past its expiry time → wiped from RAM + marked deleted
```

---

## Security Features

| Feature | Implementation |
|---------|---------------|
| File encryption | AES-256 CBC with random IV per upload |
| Password storage | bcrypt hashing (never plain text) |
| Auth tokens | JWT with expiry |
| File storage | RAM only — `dict` in Python process memory |
| Auto-delete | APScheduler TTL + confirmed download trigger |
| Screenshot block | FLAG_SECURE on Android (Flutter WindowManager) |
| Transport security | HTTPS recommended for production |

---

## Environment Variables (.env)

| Variable | Default | Description |
|----------|---------|-------------|
| SECRET_KEY | (change this!) | Used for JWT signing and AES key derivation |
| ALGORITHM | HS256 | JWT algorithm |
| ACCESS_TOKEN_EXPIRE_MINUTES | 60 | JWT token lifetime |
| DATABASE_URL | sqlite:///./securefileshare.db | Database connection |
| MAX_FILE_SIZE_MB | 50 | Max upload file size |

**Always change SECRET_KEY before sharing or deploying.**

---

## For College Submission

This project demonstrates:
- Secure software design principles
- REST API development with FastAPI
- Mobile app development with Flutter
- AES-256 symmetric encryption
- JWT-based authentication
- In-memory data management
- Automated background tasks (APScheduler)
- Privacy-by-design (zero persistent file storage)
