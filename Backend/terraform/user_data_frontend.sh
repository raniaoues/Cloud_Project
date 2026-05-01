#!/bin/bash
set -e

echo "=== UPDATE SYSTEM ==="
apt update -y
apt upgrade -y

echo "=== INSTALL NGINX + DEPENDENCIES ==="
apt install -y nginx git curl unzip

systemctl enable nginx
systemctl start nginx

echo "=== INSTALL NODEJS LTS ==="
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

node -v
npm -v

echo "=== CLONE REPOSITORY ==="
cd /home/ubuntu
git clone ${github_repo} app

cd /home/ubuntu/app/client

echo "=== INSTALL ANGULAR DEPENDENCIES ==="
npm install -g @angular/cli
npm install

echo "=== BUILD ANGULAR APP ==="
npm run build --configuration production

echo "=== DETECT DIST FOLDER ==="

DIST_DIR=$(ls dist | head -n 1)

if [ -z "$DIST_DIR" ]; then
  echo "ERROR: dist folder not found"
  exit 1
fi

BUILD_PATH="dist/$DIST_DIR"

echo "Using build path: $BUILD_PATH"

if [ ! -d "$BUILD_PATH" ]; then
  echo "ERROR: invalid build path"
  exit 1
fi

echo "=== DEPLOY TO NGINX ==="
rm -rf /var/www/html/*
cp -r $BUILD_PATH/* /var/www/html/

echo "=== FIX API URL ==="
find /var/www/html -type f -name "*.js" -exec sed -i \
"s|http://localhost:3000|http://${alb_dns_name}|g" {} +

echo "=== FIX PERMISSIONS ==="
chown -R www-data:www-data /var/www/html

echo "=== RESTART NGINX ==="
systemctl restart nginx

echo "=== FRONTEND DEPLOYED SUCCESSFULLY ==="