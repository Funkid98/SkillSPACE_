# SkillSpace (PFE)

A full-stack application with a Flutter frontend and Node.js backend.

## Getting Started (Collaborator Guide)

To run the project locally using Docker, follow these steps:

### 1. Prerequisites
- [Install Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Ensure Docker is running.

### 2. Environment Configuration
Clone the repository and create a `.env` file in the root directory by copying the template:
```bash
cp .env.example .env
```
Open the `.env` file and fill in the required values (MongoDB URI, JWT Secret, etc.).

### 3. Run with Docker Compose
Run the following command in the root directory:
```bash
docker-compose up -d
```
This will build (if necessary) and start both the frontend and backend containers.

### 4. Access the Application
- **Frontend**: [http://localhost](http://localhost)
- **Backend API**: [http://localhost:3000/api](http://localhost:3000/api)

## Development Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Express.js Documentation](https://expressjs.com/)
