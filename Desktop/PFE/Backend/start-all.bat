@echo off
echo Starting all backend services...

cd /d "%~dp0"

start "Candidat Service" cmd /k "cd candidat-service && npm start"
start "Login/Register Service" cmd /k "cd login-register-services && npm start"
start "Offer Service" cmd /k "cd offer-service && npm start"
start "Recruter Service" cmd /k "cd recruter-service && npm start"
start "Formateur Service" cmd /k "cd ..\TrainerProfile-main\backend && npm start"
start "Interview Service" cmd /k "cd interview-service && npm start"
start "Api Gateway" cmd /k "cd api-gateway && npm start"
echo All services are starting in separate windows!
