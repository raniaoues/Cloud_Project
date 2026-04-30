#!/bin/bash
set -e

apt update -y
apt install -y git curl

curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

cd /home/ubuntu
git clone ${github_repo} app

# ← IMPORTANT : va dans le bon sous-dossier où se trouve package.json
cd app/backend   # ← adapte selon la structure de ton repo !

cat > .env <<EOF
DB_HOST=${db_host}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
PORT=${app_port}
NODE_ENV=production
EOF

npm install
npm install -g pm2
pm2 start npm --name "app" -- start
pm2 startup systemd -u root --hp /root
pm2 save