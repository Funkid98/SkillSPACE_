w# Stage 1: Build
FROM ghcr.io/cirruslabs/flutter:stable AS build

# Create a non-root user if needed, but cirruslabs/flutter usually uses root.
# To avoid the warning, we can set HOME or just ignore it.
USER root

WORKDIR /app

# Copy the shared dependency to the parent directory of where the app will be
# This matches 'path: ../login-register' in pubspec.yaml
COPY ./login-register /login-register

# Copy the actual app
COPY ./skillspace_front .

# Get dependencies
RUN flutter pub get

# Build web
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built files
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY ./skillspace_front/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]