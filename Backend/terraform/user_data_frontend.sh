#!/bin/bash
set -euxo pipefail

echo "=============================="
echo " FRONTEND DEPLOY START"
echo "=============================="

APP_DIR="/home/ubuntu/app"
REPO_URL="${github_repo}"

# ============================================
# 1. SYSTEM UPDATE + INSTALLS
# ============================================
echo "Installing system packages..."

apt update -y
apt upgrade -y
apt install -y nginx git curl unzip

systemctl enable nginx
systemctl start nginx

# ============================================
# 2. NODEJS INSTALL (LTS 18)
# ============================================
echo "Installing Node.js..."

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

# ============================================
# 3. CLONE PROJECT
# ============================================
echo "Cloning repository..."

mkdir -p "$APP_DIR"
chown -R ubuntu:ubuntu "$APP_DIR"

if [ ! -d "$APP_DIR/.git" ]; then
  sudo -u ubuntu git clone "$REPO_URL" "$APP_DIR"
else
  cd "$APP_DIR"
  sudo -u ubuntu git pull
fi

# ============================================
# 4. INSTALL & BUILD ANGULAR
# Le projet Angular est dans le sous-dossier "client/"
# ============================================
cd "$APP_DIR/client"

echo "Installing Angular CLI and dependencies..."
npm install -g @angular/cli@latest
sudo -u ubuntu npm install

echo "Building Angular (production)..."
# --output-path force le chemin de sortie dans /tmp/ng-dist pour éviter
# toute ambiguïté selon la version d'Angular
sudo -u ubuntu npx ng build --configuration production --output-path /tmp/ng-dist

echo "================ DIST CONTENT ================"
ls -Rla /tmp/ng-dist || true
echo "============================================="

# Angular 17+ (Vite/esbuild) place les fichiers dans /tmp/ng-dist/browser/
# Angular 15-16 les place directement dans /tmp/ng-dist/
if [ -d "/tmp/ng-dist/browser" ]; then
  BUILD_PATH="/tmp/ng-dist/browser"
else
  BUILD_PATH="/tmp/ng-dist"
fi

echo "Detected build path: $BUILD_PATH"

if [ ! -f "$BUILD_PATH/index.html" ]; then
  echo "❌ ERROR: index.html not found in $BUILD_PATH !"
  exit 1
fi

# ============================================
# 5. DEPLOY TO NGINX
# ============================================
echo "Deploying to nginx..."

rm -rf /var/www/html/*
cp -r "$BUILD_PATH"/. /var/www/html/

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "Files deployed:"
ls -la /var/www/html

# ============================================
# 6. NGINX CONFIG — SPA routing
# ============================================
echo "Configuring nginx..."

cat > /etc/nginx/sites-available/default <<'NGINXEOF'
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log warn;

    # Angular SPA : toutes les routes renvoyées vers index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache des assets statiques
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
NGINXEOF

nginx -t
systemctl restart nginx

# ============================================
# 7. HEALTH CHECKS
# ============================================
echo "================ HEALTH CHECKS ================"

echo "Nginx status:"
systemctl status nginx --no-pager || true

echo "Testing localhost:"
sleep 2
curl -s -o /dev/null -w "HTTP status: %%{http_code}\n" http://localhost || true

echo "Open ports:"
ss -ltnp || true

echo "================================================"
echo "✅ FRONTEND DEPLOY FINISHED"