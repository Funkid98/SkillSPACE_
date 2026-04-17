const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const formateurRoutes = require('./routes/formateurRoutes');

const app = express();
app.use(express.json());
app.use(cors());

const MONGODB_URI = 'mongodb+srv://tunirideadmin:TuniridePassword2024@cluster0.lsy8lni.mongodb.net/skillspace_formateur_test?retryWrites=true&w=majority';

mongoose.connect(MONGODB_URI)
  .then(() => console.log('✅ Connected to isolated local MongoDB (skillspace_test)'))
  .catch(err => console.error('❌ MongoDB Connection Error:', err));

app.get('/', (req, res) => {
  res.send('Isolated Formateur Backend is running!');
});

app.use('/api/formateur', formateurRoutes);

const PORT = 5000;
app.listen(PORT, () => {
  console.log(`🚀 Isolated Test Server running on http://localhost:${PORT}`);
});
