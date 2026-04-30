#!/bin/bash   
set -e

# ── Mise à jour et installation de nginx ──
apt update -y
apt install -y nginx git

# ── Cloner votre frontend ──
cd /tmp
git clone ${github_repo} frontend-app

# ── Copier les fichiers dans le dossier de nginx ──
cp -r /tmp/frontend-app/frontend/* /var/www/html/
# Adaptez ce chemin selon la structure de votre dépôt

# ── Remplacer l'URL de l'API par le DNS de l'ALB ──
# Votre frontend doit appeler l'ALB, jamais directement une IP EC2 !
find /var/www/html -name "*.js" -o -name "*.html" | xargs sed -i \
  "s|http://localhost:${app_port}|http://${alb_dns_name}|g"

# ── Démarrer nginx ──
systemctl start nginx
systemctl enable nginx

echo "Frontend déployé avec succès "