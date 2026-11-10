#!/bin/sh
set -e

: "${PORT:=8080}"
: "${XUI_USER:=admin}"
: "${XUI_PASS:?XUI_PASS is required - set it in Railway > Variables}"

mkdir -p /etc/x-ui /run/nginx

gen() { cat /proc/sys/kernel/random/uuid | tr -d '-' | cut -c1-10; }

# اگر مسیرها را دستی ندادی، خودکار و تصادفی ساخته و ذخیره می‌شوند
if [ -z "$PANEL_PATH" ]; then
    [ -f /etc/x-ui/.panel_path ] || gen > /etc/x-ui/.panel_path
    PANEL_PATH="$(cat /etc/x-ui/.panel_path)"
fi
if [ -z "$WS_PATH" ]; then
    [ -f /etc/x-ui/.ws_path ] || gen > /etc/x-ui/.ws_path
    WS_PATH="$(cat /etc/x-ui/.ws_path)"
fi
export PORT PANEL_PATH WS_PATH XUI_USER XUI_PASS

cd /app

# پورت داخلی پنل و مسیر آن
./x-ui setting -port 2053 -webBasePath "/${PANEL_PATH}/" \
    || echo "WARNING: could not apply panel port/path settings"

# یوزر/پسورد فقط بار اول (تغییرات بعدی داخل پنل پاک نمی‌شود)
if [ ! -f /etc/x-ui/.initialized ]; then
    ./x-ui setting -username "$XUI_USER" -password "$XUI_PASS"
    touch /etc/x-ui/.initialized
fi

envsubst '${PORT} ${PANEL_PATH} ${WS_PATH}' \
    < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
nginx -t

echo "=============================================="
echo "PANEL PATH : /${PANEL_PATH}/"
echo "WS PATH    : /${WS_PATH}"
echo "=============================================="

./x-ui &
sleep 2

# ساخت خودکار inbound و چاپ لینک (پس‌زمینه)
/init-inbound.sh &

exec nginx -g 'daemon off;'
