#!/bin/bash
set -e

echo "Starting X-UI + nginx reverse proxy..."

export NGINX_PORT="${PORT:-3000}"

cd /usr/local/x-ui

echo "Applying panel settings via x-ui CLI..."
: "${XUI_USERNAME:?Missing XUI_USERNAME}"
: "${XUI_PASSWORD:?Missing XUI_PASSWORD}"

./x-ui setting -username "$XUI_USERNAME" -password "$XUI_PASSWORD" -port 2053 -webBasePath /managepanel/

echo "Building nginx.conf for port: $NGINX_PORT"
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "Starting x-ui in background..."
./x-ui &
X_UI_PID=$!

sleep 2

echo "Starting nginx in foreground on port $NGINX_PORT..."
nginx -t
exec nginx -g "daemon off;"
