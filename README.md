# QRly

QRly is a responsive, privacy-first QR workspace built with Dart and Flutter Web.

## Features

- Create QR codes for websites, text, Wi-Fi, email, and phone numbers
- Customize QR colors with a live preview
- Scan QR codes from a browser camera
- Add captured content manually when a camera is unavailable
- Search and filter locally stored history
- Light and dark themes
- Responsive desktop navigation and mobile bottom navigation
- Installable web-app manifest

All history stays in the browser via `shared_preferences`; there is no server or account.

## Run locally

1. Install the current stable [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Enable web support: `flutter config --enable-web`
3. In this folder, run `flutter pub get`.
4. Start the app with `flutter run -d chrome`.

For a production build, run `flutter build web --release`. The deployable files will be in `build/web`.

Camera access requires `localhost` during development or HTTPS in production.

## GitHub Pages

The included GitHub Actions workflow deploys automatically after every push to
the `main` branch. In the repository Settings, select **Pages** and set
**Build and deployment** to **GitHub Actions**. The published URL will be
`https://bhanzeeandres10-tech.github.io/kyellbhanzeeandress/`.

