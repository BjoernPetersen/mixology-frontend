FROM ghcr.io/blindfoldedsurgery/flutter:1.1.0-3.22 AS builder

COPY --chown=app [ "pubspec.yaml", "pubspec.lock", "./" ]

RUN flutter pub get --enforce-lockfile

COPY --chown=app . .

RUN dart run build_runner build

RUN flutter build web

FROM nginxinc/nginx-unprivileged:1.27

COPY --from=builder --chown=nginx /app/build/web /usr/share/nginx/html/

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
