FROM ghcr.io/mhsanaei/3x-ui:latest

RUN apk add --no-cache nginx gettext curl

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /start.sh
COPY init-inbound.sh /init-inbound.sh

# حذف CRLF احتمالی ویندوز + اجرایی کردن
RUN sed -i 's/\r$//' /start.sh /init-inbound.sh \
    && chmod +x /start.sh /init-inbound.sh

ENTRYPOINT ["/start.sh"]
CMD []
