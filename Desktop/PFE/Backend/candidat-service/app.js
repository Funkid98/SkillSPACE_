require('dotenv').config()
const express = require('express')
const cors = require('cors')
const candidatRoutes = require('./src/routes/candidat-route')
const cvRoutes = require('./src/routes/cv-route')
const mongoose = require('mongoose')


const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/skillspace';

const app = express()
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}))
app.use(express.json())
app.use('/candidat', candidatRoutes)
app.use('/cv', cvRoutes)

const PORT = process.env.PORT || 5000

mongoose.connect(mongoURI)
    .then(() => {
        console.log('MongoDB connected')
        app.listen(PORT, '0.0.0.0', () => console.log(`Candidat service running on :${PORT}`))
    })
    .catch(err => console.error('MongoDB connection error:', err));