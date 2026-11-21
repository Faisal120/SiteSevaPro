# SiteSeva Pro — local run guide

## 1. Backend

```bash
cd /Users/pro/Downloads/SiteSevaPro-main/backend
venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

The backend reads MongoDB, admin, JWT, Cloudinary and AI configuration from
`backend/.env`. The health endpoint is `http://127.0.0.1:8000/api/`.

## 2. Web/admin panel

```bash
cd /Users/pro/Downloads/SiteSevaPro-main/frontend
npm start
```

Open `http://localhost:3000`. Super-admin credentials are configured in
`backend/.env` as `SUPER_ADMIN_EMAIL` and `SUPER_ADMIN_PASSWORD`.

## 3. Flutter app

The production mobile source is available in both locations:

- `/Users/pro/StudioProjects/siteseva` (Android Studio project)
- `/Users/pro/Downloads/SiteSevaPro-main/studio-mobile` (verified workspace mirror)

For the Android emulator, the default API URL is already
`http://10.0.2.2:8000/api`:

```bash
cd /Users/pro/StudioProjects/siteseva
flutter pub get
flutter run
```

For iOS/macOS or a custom host, override the API URL:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

For a physical Android/iPhone device, use the Mac's LAN IP instead of
`127.0.0.1` or `10.0.2.2`.

Release builds default to `https://api.sitesevapro.in/api`. The verified
smoke-test APK and AAB are at:

- `/Users/pro/Downloads/SiteSevaPro-main/output/SiteSevaPro-1.0.0-production-smoke.apk`
- `/Users/pro/Downloads/SiteSevaPro-main/output/SiteSevaPro-1.0.0-production-smoke.aab`

These artifacts use the Android debug certificate. Configure
`android/key.properties` from `android/key.properties.example` before a Play
Store upload. Hostinger VPS, DNS, TLS, Firebase service account, and production
deployment steps are in `deploy/HOSTINGER_DEPLOYMENT.md`.

## Verified checks

- Backend imports/compiles and exposes 139 unique REST operations.
- Live backend health and super-admin login return HTTP 200.
- All 101 mobile REST operations have matching live backend routes.
- Notification device registration returns HTTP 200 and WebSocket ping/pong works.
- React production build completes successfully without warnings.
- Flutter analyze reports no issues; all 238 tests pass.
- Android release APK and AAB compile successfully for the production API domain.
