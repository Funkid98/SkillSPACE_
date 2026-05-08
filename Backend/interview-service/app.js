require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const interviewRoutes = require('./routes/interview.routes');

const app = express();

app.use(cors());
app.use(express.json());

// Routes
app.use('/api/interview', interviewRoutes);

// Database connection
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB (interview)'))
  .catch((err) => console.error('MongoDB connection error:', err));

const PORT = process.env.PORT || 5005;

app.listen(PORT, () => {
  console.log(`Interview Service running on port ${PORT}`);
});
