# Required GitHub Secrets

## For CI/CD to work, add these secrets to your repository:

### Settings > Secrets and variables > Actions > New repository secret

| Secret Name | Description |
|---|---|
| `GOOGLE_SERVICES_JSON` | Contents of `android/app/google-services.json` |
| `FIREBASE_OPTIONS` | Contents of `lib/firebase_options.dart` |

## How to add secrets

1. Go to your repository on GitHub
2. Click **Settings**
3. Click **Secrets and variables** in the left sidebar
4. Click **Actions**
5. Click **New repository secret**
6. Add each secret from the table above

## Notes
- The `google-services.json` and `firebase_options.dart` files
  are excluded from the repository via `.gitignore` for security
- The CI/CD will inject them from secrets during the build
- For local development, keep these files locally and never commit them