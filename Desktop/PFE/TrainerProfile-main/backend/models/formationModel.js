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
  rating: { type: Number, default: 0 },
  reviewCount: { type: Number, default: 0 },
  price: { type: Number, default: 0 },
  duration: { type: String, required: true }, // e.g., "12h"
  category: { type: String, required: true },
  imageUrl: { type: String },
}, {
  timestamps: true
});

const Formation = mongoose.model('Formation', formationSchema);
module.exports = Formation;
