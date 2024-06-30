FROM ghcr.io/cirruslabs/flutter:3.22.2 AS builder

WORKDIR /repo

COPY [ "pubspec.yaml", "pubspec.lock", "./" ]

RUN flutter pub get

COPY . .

RUN dart run build_runner build

RUN flutter build web

FROM nginxinc/nginx-unprivileged:1.27

COPY --from=builder --chown=nginx /repo/build/web /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
