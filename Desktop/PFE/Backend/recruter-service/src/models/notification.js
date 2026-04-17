const mongoose = require('mongoose');

const notificationSchema = mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'Recruiter', required: true },
    senderId: { type: String, required: true }, // Candidate ID
    senderName: { type: String, default: 'Un candidat' },
    senderEmail: { type: String },
    message: { type: String, required: true },
    type: { type: String, enum: ['APPLICATION', 'SYSTEM'], default: 'APPLICATION' },
    read: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
