const mongoose = require('mongoose')


const userSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    prenom: { type: String, required: true },
    nom: { type: String, required: true },
    role: {
        type: String,
        enum: ['candidat', 'recruteur', 'formateur'],
        default: 'candidat',
    },
    isVerified: {
        type: Boolean,
        default: false,
    },
    jobtitle: { type: String, default: '' },
    telephone: { type: String, default: '' },
    localisation: { type: String, default: '' },
    bio: { type: String, default: '' },
    skills: { type: [String], default: [] },
    cv_path: { type: String, default: '' },
    completion_percent: { type: Number, default: 30 },
    resetOtp: {
        type: String,
        default: null,
    },
    resetOtpExpires: {
        type: Date,
        default: null,
    },
}, { timestamps: true, collection: 'candidats' })

module.exports = mongoose.model('User', userSchema)