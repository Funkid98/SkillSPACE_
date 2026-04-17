# Stage 1: Build
FROM ghcr.io/cirruslabs/flutter:stable AS build

USER root

WORKDIR /app

COPY ./login-register /login-register

COPY ./skillspace_front/pubspec.yaml ./skillspace_front/pubspec.lock ./
RUN flutter pub get

COPY ./skillspace_front .

# Build web
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY ./skillspace_front/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]