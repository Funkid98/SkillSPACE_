const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');


const certificationSchema = new mongoose.Schema({
  name: { type: String, required: true },
  issuer: { type: String, required: true },
  year: { type: String, required: true },
  image: { type: String }, // Base64 thumbnail image
  fileType: { type: String, default: 'image' }, // 'image' or 'pdf'
  fullFile: { type: String }, // Base64 of the original document
});

const formateurSchema = new mongoose.Schema({

  password: { 
    type: String, 
    required: [true, 'Le mot de passe est requis'],
    minlength: 6 
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
  },
  resetOtp: {
    type: String,
    default: null,
  },
  resetOtpExpires: {
    type: Date,
    default: null,
  },
  signupOtp: {
    type: String,
    default: null,
  },
  signupOtpExpires: {
    type: Date,
    default: null,
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
}, {
  timestamps: true
});

// Hash password before saving
formateurSchema.pre('save', async function () {
  if (!this.isModified('password')) {
    return;
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Compare password
formateurSchema.methods.matchPassword = async function (enteredPassword) {
  if (!this.password) return false;
  return await bcrypt.compare(enteredPassword, this.password);
};

const Formateur = mongoose.model('Formateur', formateurSchema);
module.exports = Formateur;
