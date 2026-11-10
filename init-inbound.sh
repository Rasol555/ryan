#!/bin/sh
# ساخت خودکار inbound (VLESS + WebSocket روی پورت 10000) و چاپ لینک کلاینت در لاگ.
# اگر هر مرحله‌ای خطا داد، سرویس خراب نمی‌شود؛ inbound را دستی از پنل بساز.

BASE="http://127.0.0.1:2053/${PANEL_PATH}/"
DONE=/etc/x-ui/.inbound_done
UUID_FILE=/etc/x-ui/.client_uuid
DOMAIN="${RAILWAY_PUBLIC_DOMAIN:-YOUR-DOMAIN.up.railway.app}"
JAR=/tmp/cookies.txt

print_link() {
    echo "=============================================="
    echo "VLESS LINK (copy into v2rayNG / Hiddify):"
    echo "vless://$(cat "$UUID_FILE")@${DOMAIN}:443?encryption=none&security=tls&sni=${DOMAIN}&type=ws&host=${DOMAIN}&path=%2F${WS_PATH}#Railway-3xui"
    echo "PANEL: https://${DOMAIN}/${PANEL_PATH}/"
    echo "=============================================="
}

if [ -f "$DONE" ]; then
    print_link
    exit 0
fi

# منتظر بالا آمدن پنل
i=0
until curl -s -o /dev/null "${BASE}"; do
    i=$((i + 1))
    if [ "$i" -ge 40 ]; then
        echo "init-inbound: panel not ready, skipping"
        exit 0
    fi
    sleep 2
done

[ -f "$UUID_FILE" ] || cat /proc/sys/kernel/random/uuid > "$UUID_FILE"
UUID="$(cat "$UUID_FILE")"
SUBID="$(echo "$UUID" | tr -d '-' | cut -c1-16)"

# ورود
LOGIN="$(curl -s -c "$JAR" -X POST "${BASE}login" \
    --data-urlencode "username=${XUI_USER}" \
    --data-urlencode "password=${XUI_PASS}")"
if ! echo "$LOGIN" | grep -Eq '"success" *: *true'; then
    echo "init-inbound: login failed, create the inbound manually in the panel"
    exit 0
fi

SETTINGS="{\"clients\":[{\"id\":\"${UUID}\",\"flow\":\"\",\"email\":\"user1\",\"limitIp\":0,\"totalGB\":0,\"expiryTime\":0,\"enable\":true,\"tgId\":\"\",\"subId\":\"${SUBID}\",\"comment\":\"\",\"reset\":0}],\"decryption\":\"none\",\"fallbacks\":[]}"
STREAM="{\"network\":\"ws\",\"security\":\"none\",\"externalProxy\":[{\"forceTls\":\"tls\",\"dest\":\"${DOMAIN}\",\"port\":443,\"remark\":\"\"}],\"wsSettings\":{\"acceptProxyProtocol\":false,\"path\":\"/${WS_PATH}\",\"host\":\"\",\"headers\":{}}}"
SNIFF='{"enabled":true,"destOverride":["http","tls","quic","fakedns"],"metadataOnly":false,"routeOnly":false}'

RESP="$(curl -s -b "$JAR" -X POST "${BASE}panel/api/inbounds/add" \
    --data-urlencode "up=0" \
    --data-urlencode "down=0" \
    --data-urlencode "total=0" \
    --data-urlencode "remark=railway" \
    --data-urlencode "enable=true" \
    --data-urlencode "expiryTime=0" \
    --data-urlencode "listen=127.0.0.1" \
    --data-urlencode "port=10000" \
    --data-urlencode "protocol=vless" \
    --data-urlencode "settings=${SETTINGS}" \
    --data-urlencode "streamSettings=${STREAM}" \
    --data-urlencode "sniffing=${SNIFF}")"

if echo "$RESP" | grep -Eq '"success" *: *true'; then
    touch "$DONE"
    print_link
else
    echo "init-inbound: add inbound failed: $RESP"
    echo "create the inbound manually in the panel (VLESS, 127.0.0.1:10000, ws, path /${WS_PATH})"
fi
rm -f "$JAR"
