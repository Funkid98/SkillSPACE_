const mongoose = require('mongoose');
const Match = require('../src/models/match');

async function checkMatches() {
    try {
        await mongoose.connect('mongodb://localhost:27017/skillspace');
        const total = await Match.countDocuments();
        const analyzing = await Match.countDocuments({ status: 'ANALYSING' });
        const completed = await Match.countDocuments({ status: 'COMPLETED' });
        
        console.log(`Total Matches: ${total}`);
        console.log(`Analyzing: ${analyzing}`);
        console.log(`Completed: ${completed}`);
        
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

checkMatches();
