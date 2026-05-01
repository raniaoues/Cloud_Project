#!/bin/bash
set -e

apt update -y
apt install -y nginx git curl

curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

cd /home/ubuntu
git clone ${github_repo} app

cd /home/ubuntu/app/client

npm install -g @angular/cli
npm install

npm run build --configuration production

echo "Build result:"
ls -R dist

DIST_PATH=$(find dist -type d -name "browser" | head -n 1)
if [ -z "$DIST_PATH" ]; then
  DIST_PATH=$(find dist -type d | head -n 1)
fi

echo "Using: $DIST_PATH"

rm -rf /var/www/html/*
cp -r $DIST_PATH/* /var/www/html/

systemctl restart nginx