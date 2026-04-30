#!/bin/bash
set -e

# ── Install dependencies ──
apt update -y
apt install -y nginx git curl nodejs npm

# ── Install Node (version stable pour Angular) ──
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# ── Clone repo ──
cd /tmp
git clone ${github_repo} app

# ── Aller dans Angular project (IMPORTANT: client) ──
cd app/client

# ── Installer Angular dependencies ──
npm install

# ── Build Angular production ──
npm run build --configuration production

# ── Nettoyer nginx default ──
rm -rf /var/www/html/*

# ── Copier build Angular vers nginx ──
# Angular output est souvent dans dist/client (ou dist/<project-name>)
cp -r dist/* /var/www/html/

# ── Config nginx (SPA Angular fix) ──
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# ── restart nginx ──
systemctl restart nginx
systemctl enable nginx

echo "Frontend Angular déployé avec succès"