const mongoose = require('mongoose');

const notificationSchema = mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    senderId: { type: String, required: true }, // Recruiter ID
    senderName: { type: String, default: 'Un recruteur' },
    senderEmail: { type: String },
    message: { type: String, required: true },
    offerId: { type: String },
    offerTitle: { type: String },
    rejectionReason: { type: String },
    meetingLink: { type: String },
    interviewDate: { type: String },
    interviewTime: { type: String },
    type: { type: String, enum: ['CONTACT', 'SYSTEM', 'INTERVIEW_SCHEDULED', 'APPLICATION_REJECTED', 'REJECTION'], default: 'CONTACT' },
    read: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Notification', notificationSchema);
