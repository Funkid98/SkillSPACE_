const mongoose = require('mongoose');

const offerSchema = mongoose.Schema({
    recruiter: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'Recruiter'
    },
    title: { type: String, required: true },
    description: { type: String, required: true },
    company: { type: String, required: true },
    location: { type: String, required: true },
    salary: { type: String },
    type: { type: String, enum: ['Full-time', 'Part-time', 'Contract', 'Freelance'], default: 'Full-time' },
    requirements: [String],
    date: { type: Date, default: Date.now }
}, { timestamps: true });

module.exports = mongoose.model('Offer', offerSchema);
