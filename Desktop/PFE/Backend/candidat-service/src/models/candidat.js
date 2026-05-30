const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    prenom: { type: String, required: true },
    nom: { type: String, required: true },
    role: {
      type: String,
      enum: ["candidat", "recruteur", "formateur"],
      default: "candidat",
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    jobtitle: { type: String, default: "" },
    sector: { type: String, default: "" },
    telephone: { type: String, default: "" },
    localisation: { type: String, default: "" },
    bio: { type: String, default: "" },
    skills: {
      type: [
        {
          name: { type: String, required: true },
          percent: { type: Number, default: 50, min: 0, max: 100 },
        },
      ],
      default: [],
    },
    cv_path: { type: String, default: "" },
    completion_percent: { type: Number, default: 30 },
    enrolledFormations: [
      {
        formationId: { type: String, required: true },
        enrolledAt: { type: Date, default: Date.now },
        aiReason: { type: String, default: "" },
        status: {
          type: String,
          enum: ["ENROLLED", "COMPLETED"],
          default: "ENROLLED",
        },
        rating: { type: Number, default: 0, min: 0, max: 5 },
        review: { type: String, default: "" },
      },
    ],
    resetOtp: {
      type: String,
      default: null,
    },
    resetOtpExpires: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true, collection: "candidats" },
);

module.exports = mongoose.model("User", userSchema);
