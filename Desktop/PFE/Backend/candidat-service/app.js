const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, './.env') });

const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const candidatRoutes = require('./src/routes/candidat-route');
const cvRoutes = require('./src/routes/cv-route');
const quizRoutes = require('./src/routes/quiz-route');
const mongoose = require('mongoose');

const mongoURI = process.env.MONGODB_URI;

if (!mongoURI) {
    console.error('❌ FATAL ERROR: MONGODB_URI is not defined in .env');
    process.exit(1);
}

const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000').split(',').map((o) => o.trim());

const app = express()
app.use(cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error(`CORS blocked: ${origin}`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}))
app.use(express.json())
app.use(cookieParser())
app.use('/candidat', candidatRoutes)
app.use('/cv', cvRoutes)
app.use('/quiz', quizRoutes)

const PORT = process.env.PORT || 5000

mongoose.connect(mongoURI)
    .then(() => {
        console.log('MongoDB connected')
        app.listen(PORT, '0.0.0.0', () => console.log(`Candidat service running on :${PORT}`))
    })
    .catch(err => console.error('MongoDB connection error:', err));