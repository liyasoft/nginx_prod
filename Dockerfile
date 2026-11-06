FROM registry.cn-hangzhou.aliyuncs.com/acs/nginx:latest

COPY nginx.conf /etc/nginx/nginx.conf
COPY vhost/ /etc/nginx/vhost/
COPY ssl/ /etc/nginx/ssl/

RUN rm -f /etc/nginx/conf.d/default.conf \
    && chmod 644 /etc/nginx/ssl/*.pem \
    && chmod 600 /etc/nginx/ssl/*.key

EXPOSE 80 443
STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
