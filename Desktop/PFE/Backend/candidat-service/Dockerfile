# Build Stage
FROM node:18-alpine

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy source code
COPY . .

# Expose port 5000
EXPOSE 5000

# Start the service
CMD ["npm", "start"]
