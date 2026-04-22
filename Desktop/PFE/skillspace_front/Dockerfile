# Stage 1: Base image with Flutter
FROM ghcr.io/cirruslabs/flutter:stable AS base
USER root

# Stage 2: Build Landing (Main App)
FROM base AS build-landing
WORKDIR /app
# Main app depends on login-register and trainer folders via path dependencies
COPY ./login-register /login-register
COPY ./TrainerProfile-main /TrainerProfile-main
COPY ./skillspace_front/pubspec.yaml ./skillspace_front/pubspec.lock ./
RUN flutter pub get
COPY ./skillspace_front .
RUN flutter build web --release --base-href /

# Stage 3: Build Auth
FROM base AS build-auth
WORKDIR /app
COPY ./login-register/pubspec.yaml ./login-register/pubspec.lock ./
RUN flutter pub get
COPY ./login-register .
RUN flutter build web --release --base-href /auth/

# Stage 4: Build Trainer
FROM base AS build-trainer
WORKDIR /app
COPY ./TrainerProfile-main/frontend/pubspec.yaml ./TrainerProfile-main/frontend/pubspec.lock ./
RUN flutter pub get
COPY ./TrainerProfile-main/frontend .
RUN flutter build web --release --base-href /trainer/

# Stage 5: Build Recruiter
FROM base AS build-recruiter
WORKDIR /app
COPY ./login-register /login-register
COPY ./TrainerProfile-main /TrainerProfile-main
COPY ./skillspace_front/pubspec.yaml ./skillspace_front/pubspec.lock ./
RUN flutter pub get
COPY ./skillspace_front .
RUN flutter build web --release --base-href /recruiter/

# Stage 6: Build Candidat
FROM base AS build-candidat
WORKDIR /app
COPY ./login-register /login-register
COPY ./TrainerProfile-main /TrainerProfile-main
COPY ./skillspace_front/pubspec.yaml ./skillspace_front/pubspec.lock ./
RUN flutter pub get
COPY ./skillspace_front .
RUN flutter build web --release --base-href /candidat/

# Stage 7: Final Nginx
FROM nginx:alpine

# Copy Landing to root
COPY --from=build-landing /app/build/web /usr/share/nginx/html

# Copy Auth to /auth
COPY --from=build-auth /app/build/web /usr/share/nginx/html/auth

# Copy Trainer to /trainer
COPY --from=build-trainer /app/build/web /usr/share/nginx/html/trainer

# Copy Recruiter to /recruiter
COPY --from=build-recruiter /app/build/web /usr/share/nginx/html/recruiter

# Copy Candidat to /candidat
COPY --from=build-candidat /app/build/web /usr/share/nginx/html/candidat

# Copy Unified Nginx config
COPY ./skillspace_front/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]