# SiteSeva Pro production deployment

The production layout uses `sitesevapro.in` for the React website/admin panel
and `api.sitesevapro.in` for FastAPI, REST, and notification WebSockets. A
Hostinger VPS is required because FastAPI, WebSockets, and the background
service need a persistent Python process; ordinary static/shared hosting is not
enough for this backend.

## Accounts and secrets required

- Hostinger VPS public IPv4 address and SSH root/sudo access.
- DNS control for `sitesevapro.in`.
- MongoDB Atlas connection string, with the VPS IP allowed in Network Access.
- Cloudinary credentials used by reports, documents, branding, and receipts.
- A long random JWT secret and final super-admin credentials.
- Firebase service-account JSON from the same Firebase project as
  `android/app/google-services.json`. Never commit this JSON.
- AI provider key if AI insights and design generation must be enabled.
- Android upload keystore plus its passwords for the Play Store bundle.

## DNS

Create these records in Hostinger hPanel after the VPS exists:

| Type | Name | Value |
| --- | --- | --- |
| A | `@` | VPS IPv4 |
| A | `api` | VPS IPv4 |
| CNAME | `www` | `sitesevapro.in` |

Wait for DNS propagation before requesting TLS certificates.

## VPS bootstrap (Ubuntu)

```bash
sudo apt update
sudo apt install -y python3-venv python3-pip nginx certbot python3-certbot-nginx
sudo adduser --system --group --home /opt/siteseva siteseva
sudo mkdir -p /opt/siteseva /var/www/siteseva/frontend /etc/siteseva
sudo chown -R siteseva:siteseva /opt/siteseva
```

Upload or clone this repository into `/opt/siteseva`, then install the API:

```bash
sudo -u siteseva python3 -m venv /opt/siteseva/venv
sudo -u siteseva /opt/siteseva/venv/bin/pip install -r /opt/siteseva/backend/requirements.txt
sudo cp deploy/siteseva.env.example /etc/siteseva/backend.env
sudo chmod 600 /etc/siteseva/backend.env
sudo cp FIREBASE_SERVICE_ACCOUNT.json /etc/siteseva/firebase-service-account.json
sudo chmod 600 /etc/siteseva/firebase-service-account.json
```

Fill `/etc/siteseva/backend.env`, then install the service and Nginx config:

```bash
sudo cp deploy/siteseva-api.service /etc/systemd/system/
sudo cp deploy/nginx-siteseva.conf /etc/nginx/sites-available/siteseva
sudo ln -s /etc/nginx/sites-available/siteseva /etc/nginx/sites-enabled/siteseva
sudo nginx -t
sudo systemctl daemon-reload
sudo systemctl enable --now siteseva-api nginx
```

Build the website/admin panel with the production API and publish it:

```bash
cd /opt/siteseva/frontend
REACT_APP_BACKEND_URL=https://api.sitesevapro.in yarn build
sudo rsync -a --delete build/ /var/www/siteseva/frontend/
```

Once all three DNS names resolve to the VPS, issue HTTPS certificates:

```bash
sudo certbot --nginx -d sitesevapro.in -d www.sitesevapro.in
sudo certbot --nginx -d api.sitesevapro.in
```

## Android production build

The release app defaults to `https://api.sitesevapro.in/api`. It can be
overridden for staging without editing code:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.sitesevapro.in
```

Create `android/key.properties` from `android/key.properties.example` or set
the four `SITESEVA_KEYSTORE_*` environment variables before producing the Play
Store AAB. A build without them is only a local smoke-test build signed with
the debug key and must not be uploaded.

## Verification

```bash
curl -fsS https://api.sitesevapro.in/api/
curl -I https://sitesevapro.in
sudo systemctl status siteseva-api --no-pager
sudo journalctl -u siteseva-api -n 100 --no-pager
```

Then sign in on Android, allow notification permission, create a payment or
attendance entry, and verify that the notification appears in the in-app inbox
and as a device push alert.
