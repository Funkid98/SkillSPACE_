const mongoose = require('mongoose');

const certificationSchema = new mongoose.Schema({
  name: { type: String, required: true },
  issuer: { type: String, required: true },
  year: { type: String, required: true },
});

const formateurSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  email: { type: String, required: true },
  phone: { type: String },
  jobTitle: { type: String },
  location: { type: String },
  bio: { type: String },
  profilePicture: { type: String }, // URL of the uploaded image
  profileCompleteness: { type: Number, default: 0 },
  expertise: [{ type: String }],
  certifications: [certificationSchema],
  socialLinks: {
    linkedIn: { type: String },
    portfolio: { type: String }
  }
}, {
  timestamps: true
});

const Formateur = mongoose.model('Formateur', formateurSchema);
module.exports = Formateur;
