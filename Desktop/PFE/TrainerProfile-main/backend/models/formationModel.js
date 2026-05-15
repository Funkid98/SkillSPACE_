const mongoose = require('mongoose');

const formationSchema = new mongoose.Schema({
  trainerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Formateur',
    required: true,
  },
  title: { type: String, required: true },
  description: { type: String },
  tags: [{ type: String }],
  studentCount: { type: Number, default: 0 },
  students: [{
    name: { type: String, required: true },
    joinedAt: { type: Date, default: Date.now },
    rating: { type: Number, default: 0 }
  }],
  rating: { type: Number, default: 0 },
  reviewCount: { type: Number, default: 0 },
  price: { type: Number, default: 0 },
  duration: { type: String, required: true }, // e.g., "12h"
  level: {
    type: String,
    enum: ['Débutant', 'Intermédiaire', 'Avancé'],
    default: 'Débutant'
  },
  category: { type: String, required: true },
  imageUrl: { type: String },
  meetLink: { type: String, required: true },
  date: { type: Date, required: true },
  time: { type: String, required: true },
  status: {
    type: String,
    enum: ['active', 'terminé'],
    default: 'active'
  },
}, {
  timestamps: true
});

const Formation = mongoose.model('Formation', formationSchema);
module.exports = Formation;
