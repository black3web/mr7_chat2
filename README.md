# MR7 Chat

<div align="center">

<!-- App icon -->
<img src="assets/icons/app_icon.svg" width="120" height="120" alt="MR7 Chat Icon"/>

### Advanced Chat & AI Platform

**Flutter app for Android and Web**

[![Build Android APK](https://github.com/USERNAME/mr7_chat/actions/workflows/ci.yml/badge.svg)](https://github.com/USERNAME/mr7_chat/actions/workflows/ci.yml)
[![Build Web](https://github.com/USERNAME/mr7_chat/actions/workflows/ci.yml/badge.svg)](https://github.com/USERNAME/mr7_chat/actions/workflows/ci.yml)

</div>

---

## Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/mr7_chat.git
cd mr7_chat
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run locally
```bash
flutter run -d chrome    # Web
flutter run              # Android (with device connected)
```

### 4. Build
```bash
flutter build web --release --base-href "/mr7_chat/"
flutter build apk --release --target-platform android-arm64
```

---

## GitHub Pages Deployment

### Automatic (recommended)
Push to `main` branch → CI/CD builds and deploys automatically.

The web app will be available at:
```
https://YOUR_USERNAME.github.io/mr7_chat/
```

### Enable GitHub Pages
1. Go to **Settings** → **Pages**
2. Set Source to **gh-pages** branch
3. Save

---

## Firebase Setup

The `lib/firebase_options.dart` and `android/app/google-services.json` files
are already configured for the `mr7-chat` Firebase project and committed to git.

**No secrets required** — builds work out of the box.

---

## AI Services Integrated

| Service | Model | Capability |
|---------|-------|-----------|
| Gemini | 2.5 Flash | Chat & Q&A |
| DeepSeek | V3.2 / R1 / Coder | Multi-model chat with memory |
| Nano Banana 2 | - | Image generation 2K |
| NanoBanana Pro | - | Image generation & editing 1K/2K/4K |
| Seedance AI | 1.0 Lite / 1.0 Pro / 1.5 Pro | Text & image to video |
| Kilwa Video | Seedance 1.5 Pro | Fast text-to-video |
| AI Music | Visco AI | Music generation with mood tags |

---

## Developer Account

- **Username:** A1
- **Password:** 5cd9e55dcaf491d32289b848adeb216e
- Unlocks full admin panel with analytics, user management, and broadcast system

---

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── firebase_options.dart        # Firebase config (committed)
├── config/
│   ├── constants.dart           # App constants & API endpoints
│   ├── routes.dart              # Navigation routes
│   └── theme.dart               # Dark red/black theme
├── l10n/
│   └── app_localizations.dart   # Arabic + English translations
├── models/                      # Data models
├── providers/                   # State management (Provider)
├── services/                    # Firebase + AI API services
├── screens/                     # UI screens
└── widgets/                     # Reusable components
```

---

## Tech Stack

- **Framework:** Flutter 3.24.5 (Dart)
- **Backend:** Firebase (Firestore, Storage, Analytics)
- **State:** Provider
- **Auth:** Custom (Firestore-based, SHA-256 hashed passwords)
- **Platforms:** Android (API 24+) & Web (PWA)

---

## License

MIT License - see [LICENSE](LICENSE) file.

---

<div align="center">
Made by <a href="https://black3web.github.io/Blackweb/">جلال</a> •
<a href="https://t.me/swc_t">Telegram</a>
</div>