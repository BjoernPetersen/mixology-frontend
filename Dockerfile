FROM nginxinc/nginx-unprivileged:1.27

COPY build/web /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
