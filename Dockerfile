FROM nginxinc/nginx-unprivileged:1.23

COPY build/web /usr/share/nginx/html/

EXPOSE 8080
