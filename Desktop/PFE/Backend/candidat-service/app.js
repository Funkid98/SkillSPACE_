const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, './.env') });

const express = require('express');
const cors = require('cors');
const candidatRoutes = require('./src/routes/candidat-route');
const cvRoutes = require('./src/routes/cv-route');
const quizRoutes = require('./src/routes/quiz-route');
const mongoose = require('mongoose');

const mongoURI = process.env.MONGODB_URI;

if (!mongoURI) {
    console.error('❌ FATAL ERROR: MONGODB_URI is not defined in .env');
    process.exit(1);
}

const app = express()
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}))
app.use(express.json())
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