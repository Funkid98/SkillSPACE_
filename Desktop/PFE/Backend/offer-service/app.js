require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const offerRoutes = require('./src/routes/offer.route');

const app = express();

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// Routes
app.use('/api/offers', offerRoutes);

// Database connection
const mongoURI = process.env.MONGODB_URI;
mongoose.connect(mongoURI)
    .then(() => {
        console.log('MongoDB Connected to SkillSpace Offers');
        const PORT = process.env.PORT || 5003;
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`Offer service running on port ${PORT}`);
        });
    })
    .catch(err => {
        console.error('MongoDB connection error:', err);
    });

app.get('/', (req, res) => {
    res.send('Offer Service API is running...');
});
