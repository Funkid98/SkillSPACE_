# Stage 1: Base image with Flutter
FROM ghcr.io/cirruslabs/flutter:3.27.3 AS base
USER root

# Stage 2: Build Landing (Main App)
FROM base AS build-landing
WORKDIR /app

# Copy all directories into their respective paths under /app so path-dependencies resolve perfectly
COPY ./login-register /app/login-register
COPY ./TrainerProfile-main /app/TrainerProfile-main
COPY ./RecruiterProfile /app/RecruiterProfile
COPY ./skillspace_front /app/skillspace_front

WORKDIR /app/skillspace_front
RUN flutter pub get
RUN flutter build web --release --base-href /

# Stage 3: Build Auth
FROM base AS build-auth
WORKDIR /app/login-register
COPY ./login-register .
RUN flutter pub get
RUN flutter build web --release --base-href /auth/

# Stage 4: Build Trainer
FROM base AS build-trainer
WORKDIR /app

# Copy Trainer and its path dependency (login-register)
COPY ./login-register /app/login-register
COPY ./TrainerProfile-main /app/TrainerProfile-main

WORKDIR /app/TrainerProfile-main/frontend
RUN flutter pub get
RUN flutter build web --release --base-href /trainer/

# Stage 5: Build Recruiter
FROM base AS build-recruiter
WORKDIR /app

# Copy Recruiter and its path dependencies
COPY ./login-register /app/login-register
COPY ./TrainerProfile-main /app/TrainerProfile-main
COPY ./RecruiterProfile /app/RecruiterProfile
COPY ./skillspace_front /app/skillspace_front

WORKDIR /app/skillspace_front
RUN flutter pub get
RUN flutter build web --release --base-href /recruiter/

# Stage 6: Build Candidat
FROM base AS build-candidat
WORKDIR /app

# Copy Candidat and its path dependencies
COPY ./login-register /app/login-register
COPY ./TrainerProfile-main /app/TrainerProfile-main
COPY ./RecruiterProfile /app/RecruiterProfile
COPY ./skillspace_front /app/skillspace_front

WORKDIR /app/skillspace_front
RUN flutter pub get
RUN flutter build web --release --base-href /candidat/

# Stage 7: Final Nginx
FROM nginx:alpine

# Copy Landing to root
COPY --from=build-landing /app/skillspace_front/build/web /usr/share/nginx/html

# Copy Auth to /auth
COPY --from=build-auth /app/login-register/build/web /usr/share/nginx/html/auth

# Copy Trainer to /trainer
COPY --from=build-trainer /app/TrainerProfile-main/frontend/build/web /usr/share/nginx/html/trainer

# Copy Recruiter to /recruiter
COPY --from=build-recruiter /app/skillspace_front/build/web /usr/share/nginx/html/recruiter

# Copy Candidat to /candidat
COPY --from=build-candidat /app/skillspace_front/build/web /usr/share/nginx/html/candidat

# Copy Unified Nginx config
COPY ./skillspace_front/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]