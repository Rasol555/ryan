# 3x-ui روی Railway (تک‌پورت، با nginx)

## چطور کار می‌کند
Railway فقط یک پورت عمومی ($PORT) به هر سرویس می‌دهد. nginx آن پورت را می‌گیرد و:
- `/PANEL_PATH/` ← پنل 3x-ui (پورت داخلی 2053)
- `/WS_PATH` ← Xray (VLESS روی WebSocket، پورت داخلی 10000)
- `/sub/` ← لینک اشتراک (پورت داخلی 2096)
- بقیه‌ی مسیرها ← 404

## مراحل
1. این ۶ فایل را در ریشه‌ی ریپوی GitHub بگذار (Add file ← Upload files).
2. Railway: New Project ← Deploy from GitHub repo ← ریپو را انتخاب کن.
3. تب **Variables**: `XUI_PASS` = یک رمز قوی (الزامی). اختیاری: `XUI_USER`، `PANEL_PATH`، `WS_PATH`.
   اگر مسیرها را ندهی، خودکار و تصادفی ساخته می‌شوند و در لاگ چاپ می‌شوند.
4. **Volume** بساز با Mount Path برابر `/etc/x-ui`.
5. Settings ← Networking ← **Generate Domain**، بعد یک بار Redeploy.
6. Deployments ← View Logs: بین خطوط `====` لینک **VLESS** و آدرس پنل چاپ شده است.

## اگر inbound خودکار ساخته نشد
در پنل بساز: VLESS، Listen `127.0.0.1`، Port `10000`، Transport `ws`، Path `/WS_PATH`، Security `none`.
در External Proxy: دامنه‌ی Railway، پورت `443`، TLS.
