const mongoose = require('mongoose');

const recruiterSchema = mongoose.Schema({
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    entreprise: { type: String, required: true },
    poste: { type: String },
    role: { type: String, default: 'recruiter' },
    date: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Recruiter', recruiterSchema);
