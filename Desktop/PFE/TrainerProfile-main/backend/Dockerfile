FROM node:20-slim

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install production dependencies
RUN npm install --production

# Copy remaining source code
COPY . .

# Expose the port from .env
EXPOSE 5004

# Start the application
CMD ["npm", "start"]
