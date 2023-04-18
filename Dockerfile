FROM nginxinc/nginx-unprivileged:1.24

COPY build/web /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
