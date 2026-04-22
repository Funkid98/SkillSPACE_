const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Formateur = require('./models/formateurModel');
require('dotenv').config();

const fixPasswords = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to DB');
    
    const formateurs = await Formateur.find({ password: { $exists: false } });
    console.log(`Found ${formateurs.length} formateurs without password`);

    for (let f of formateurs) {
      console.log(`Setting password for ${f.email}`);
      f.password = '123456'; // Default password that will be hashed by pre-save
      await f.save();
    }
    
    // Also try checking those with null or empty password
    const emptyPasswords = await Formateur.find({ password: { $in: [null, ""] } });
    console.log(`Found ${emptyPasswords.length} formateurs with null/empty password`);
    for (let f of emptyPasswords) {
      console.log(`Setting password for ${f.email}`);
      f.password = '123456';
      await f.save();
    }

    console.log('Done!');
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
};

fixPasswords();
