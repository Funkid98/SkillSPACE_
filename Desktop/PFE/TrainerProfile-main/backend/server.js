const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const formateurRoutes = require('./routes/formateurRoutes');

// Load environment variables
const dotenvPaths = [
  path.join(__dirname, '.env'),
  path.join(__dirname, '../.env'),
  path.join(process.cwd(), '.env')
];

dotenvPaths.forEach(p => {
  require('dotenv').config({ path: p });
});

const app = express();
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));
app.use(cors());

const mongo_uri = process.env.MONGODB_URI;

if (!mongo_uri) {
  console.error('❌ MONGODB_URI is not defined (checked .env files and system environment)');
  process.exit(1);
}

mongoose.connect(mongo_uri)
  .then((conn) => {
    console.log(`✅ MongoDB Connected to Host: ${conn.connection.host}`);
    console.log(`✅ Database Name: ${conn.connection.name}`);
  })
  .catch(err => console.error('❌ MongoDB Connection Error:', err));

app.get('/', (req, res) => {
  res.send('Isolated Formateur Backend is running!');
});

app.use('/api/formateur', formateurRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Isolated Test Server running on http://localhost:${PORT}`);
});
