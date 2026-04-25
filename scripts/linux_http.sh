#!/bin/bash

set -e

APACHE_PORT=8081
TOMCAT_PORT=8082
NGINX_PORT=8083

log() {
    echo "[INFO] $1"
}

ok() {
    echo "[OK] $1"
}

warn() {
    echo "[WARN] $1"
}

# APACHE
log "Verificando Apache..."

if ! dpkg -l | grep -q "^ii  apache2"; then
    sudo apt update -y > /dev/null 2>&1
    sudo apt install apache2 -y > /dev/null 2>&1
    log "Apache instalado"
else
    log "Apache ya instalado"
fi

# Configuración idempotente del puerto
sudo sed -i -E "s/^Listen .*/Listen $APACHE_PORT/" /etc/apache2/ports.conf
sudo sed -i -E "s/<VirtualHost \*:[0-9]+>/<VirtualHost *:$APACHE_PORT>/" /etc/apache2/sites-available/000-default.conf

sudo apache2ctl configtest > /dev/null
sudo systemctl restart apache2
ok "Apache activo en puerto $APACHE_PORT"

# TOMCAT 
log "Verificando Tomcat..."

if ! dpkg -l | grep -q tomcat10; then
    sudo apt install tomcat10 -y > /dev/null 2>&1
    log "Tomcat instalado"
else
    log "Tomcat ya instalado"
fi

sudo sed -i "s/port=\"8080\"/port=\"$TOMCAT_PORT\"/g" /etc/tomcat10/server.xml

sudo systemctl restart tomcat10
ok "Tomcat activo en puerto $TOMCAT_PORT"

# NGINX
log "Verificando Nginx..."

if ! dpkg -l | grep -q nginx; then
    sudo apt install nginx -y > /dev/null 2>&1
    log "Nginx instalado"
else
    log "Nginx ya instalado"
fi

sudo sed -i "s/listen 80 default_server;/listen $NGINX_PORT default_server;/g" /etc/nginx/sites-available/default

sudo systemctl restart nginx
ok "Nginx activo en puerto $NGINX_PORT"

# verificacion de puertos
log "Validando puertos..."

if ss -tuln | grep -q ":$APACHE_PORT"; then ok "Puerto $APACHE_PORT activo"; else warn "Puerto $APACHE_PORT no activo"; fi
if ss -tuln | grep -q ":$TOMCAT_PORT"; then ok "Puerto $TOMCAT_PORT activo"; else warn "Puerto $TOMCAT_PORT no activo"; fi
if ss -tuln | grep -q ":$NGINX_PORT"; then ok "Puerto $NGINX_PORT activo"; else warn "Puerto $NGINX_PORT no activo"; fi

log "Proceso finalizado"