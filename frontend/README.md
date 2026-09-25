# EduMarket Flutter Web frontend

The Flutter Web application for EduMarket lives in this directory. For complete setup, environment configuration, local URLs, test accounts, testing evidence, security notes, and known limitations, see the repository [README](../README.md).

Run locally:

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```

For a deployable bundle, use `flutter build web --dart-define=API_BASE_URL=https://api.example.edu`.
