require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./src/config/database');
const recruiterRoutes = require('./src/routes/recruiter-route');
const jobRoutes = require('./src/routes/job-route');

const app = express();

// Connect to Database
connectDB();

// Middleware
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use('/uploads', express.static('public/uploads'));

// Routes
app.use('/recruiter', recruiterRoutes);
app.use('/job', jobRoutes);

// Health check
app.get('/', (req, res) => {
    res.send('Recruiter Service is running...');
});

const PORT = process.env.PORT || 5002;

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Recruiter service running on port ${PORT}`);
});
