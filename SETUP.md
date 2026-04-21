# Setup Guide for MR7 Chat

## Prerequisites
- Flutter SDK 3.24+ (https://flutter.dev/docs/get-started/install)
- Android Studio or VS Code
- Git

## Local Development

### Clone & Install
```bash
git clone https://github.com/YOUR_USERNAME/mr7_chat.git
cd mr7_chat
flutter pub get
```

### Run on Web
```bash
flutter run -d chrome
```

### Run on Android
```bash
# Connect Android device with USB debugging enabled
flutter run
```

## Deploying to GitHub

### 1. Create GitHub repository
- Go to github.com → New repository → name it `mr7_chat`
- Leave it empty (don't add README)

### 2. Push the project
```bash
cd mr7_chat
git init
git add .
git commit -m "Initial commit: MR7 Chat v1.0.0"
git remote add origin https://github.com/YOUR_USERNAME/mr7_chat.git
git push -u origin main
```

### 3. Wait for CI/CD
- GitHub Actions runs automatically after push
- Check the **Actions** tab in your repository
- APK will be available under **Artifacts**
- Web app deploys to GitHub Pages automatically

### 4. Enable GitHub Pages
- Settings → Pages → Source: **gh-pages** branch → Save
- Your app: `https://YOUR_USERNAME.github.io/mr7_chat/`

## No Secrets Required
The project works without any GitHub Secrets configured.
Both `firebase_options.dart` and `google-services.json` are committed to git
with the public Firebase configuration for the `mr7-chat` project.