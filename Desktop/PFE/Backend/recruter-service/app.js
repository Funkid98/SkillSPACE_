require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const connectDB = require('./src/config/database');
const recruiterRoutes = require('./src/routes/recruiter-route');

const app = express();

// Connect to Database
connectDB();

// Middleware
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000').split(',').map((o) => o.trim());
app.use(cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error(`CORS blocked: ${origin}`));
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(cookieParser());
app.use('/uploads', express.static('public/uploads'));

// Routes
app.use('/recruiter', recruiterRoutes);

// Health check
app.get('/', (req, res) => {
    res.send('Recruiter Service is running...');
});

const PORT = process.env.PORT || 5002;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Recruiter service running on port ${PORT}`);
});
