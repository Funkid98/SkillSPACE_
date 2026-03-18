const mongoose = require('mongoose');

const entrepriseSchema = new mongoose.Schema(
  {
    nom: {
      type: String,
      required: [true, "Le nom de l'entreprise est requis"],
      trim: true,
      unique: true,
    },
    description: {
      type: String,
      trim: true,
    },
    siteWeb: {
      type: String,
      trim: true,
    },
    logo: {
      type: String,
    },
    localisation: {
      type: String,
      trim: true,
    },
    secteur: {
      type: String,
      trim: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Entreprise', entrepriseSchema);
