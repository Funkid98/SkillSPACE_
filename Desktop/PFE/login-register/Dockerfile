# ─── Stage 1: Build Flutter Web ───────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copier les fichiers du projet
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Compiler l'application Flutter pour le Web
RUN flutter build web --release

# ─── Stage 2: Servir avec Nginx ───────────────────────────────────────────
FROM nginx:alpine

# Supprimer la config par défaut
RUN rm -rf /usr/share/nginx/html/*

# Copier le build Flutter depuis le stage 1
COPY --from=builder /app/build/web /usr/share/nginx/html

# Exposer le port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
