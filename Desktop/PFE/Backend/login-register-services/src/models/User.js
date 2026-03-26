const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    prenom: {
      type: String,
      required: [function () { return this.role !== 'recruteur'; }, 'Le prénom est requis'],
      trim: true,
    },
    nom: {
      type: String,
      required: [function () { return this.role !== 'recruteur'; }, 'Le nom est requis'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, "L'email est requis"],
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: [true, 'Le mot de passe est requis'],
      minlength: 6,
    },
    role: {
      type: String,
      enum: ['candidat', 'recruteur', 'formateur'],
      default: 'candidat',
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    // Profile fields removed (handled by candidat-service)
    resetOtp: {
      type: String,
      default: null,
    },
    resetOtpExpires: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true, collection: 'candidats' }
);

// Hash password avant de sauvegarder
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Comparer le mot de passe
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);