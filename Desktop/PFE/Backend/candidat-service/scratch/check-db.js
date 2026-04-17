const mongoose = require('mongoose');
const mongoURI = 'mongodb+srv://youssef:skillspace2026@cluster0.lsy8lni.mongodb.net/candidat?retryWrites=true&w=majority&appName=Cluster0';

async function checkMatches() {
    try {
        await mongoose.connect(mongoURI);
        console.log('Connected to DB');
        
        const Match = mongoose.model('Match', new mongoose.Schema({}, { strict: false }));
        const matches = await Match.find({}).limit(10);
        
        console.log('Total matches found:', await Match.countDocuments());
        console.log('Sample matches:', JSON.stringify(matches, null, 2));
        
        process.exit(0);
    } catch (err) {
        console.error('Error:', err);
        process.exit(1);
    }
}

checkMatches();
