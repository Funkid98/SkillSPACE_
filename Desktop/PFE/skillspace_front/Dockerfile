# Stage 1: Build
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy the project files
COPY . .

# Get dependencies
RUN flutter pub get

# Build web
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built files
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]