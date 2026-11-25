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
- Meta WhatsApp Business account, approved message templates, permanent system
  user token, phone-number ID, app secret, and webhook verification token.
- AI provider key if AI insights and design generation must be enabled.

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
sudo apt install -y git python3-venv python3-pip nginx certbot python3-certbot-nginx
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

Before the restart, run the password-state migration against a staging copy first. It defaults to dry-run and never creates passwords or deletes records:

```bash
cd /opt/siteseva
sudo -u siteseva /opt/siteseva/venv/bin/python backend/scripts/migrate_password_setup.py
# Review the count, take an Atlas backup, then explicitly apply in the approved window:
sudo -u siteseva /opt/siteseva/venv/bin/python backend/scripts/migrate_password_setup.py --apply
```

Install Node.js 20 LTS or newer, then build the website/admin panel with the
production API and publish it:

```bash
cd /opt/siteseva/frontend
sudo -u siteseva npm ci
sudo -u siteseva env REACT_APP_BACKEND_URL=https://api.sitesevapro.in npm run build
sudo rsync -a --delete build/ /var/www/siteseva/frontend/
```

Once all three DNS names resolve to the VPS, issue HTTPS certificates:

```bash
sudo certbot --nginx -d sitesevapro.in -d www.sitesevapro.in
sudo certbot --nginx -d api.sitesevapro.in
```

## WhatsApp production setup

Complete `deploy/WHATSAPP_SETUP.md` before approving the first real contractor.
The webhook URL is `https://api.sitesevapro.in/api/whatsapp/webhook`. Subscribe
the Meta app to the WhatsApp `messages` webhook field so delivery receipts move
from `ACCEPTED` to `SENT`, `DELIVERED`, or `READ` in the super-admin panel.

## Verification

```bash
curl -fsS https://api.sitesevapro.in/api/
curl -I https://sitesevapro.in
sudo systemctl status siteseva-api --no-pager
sudo journalctl -u siteseva-api -n 100 --no-pager
```

Then test all four web roles, approve a sandbox contractor, complete activation via WhatsApp OTP, test Forgot password, and confirm
the WhatsApp delivery log in Super Admin → WhatsApp.
