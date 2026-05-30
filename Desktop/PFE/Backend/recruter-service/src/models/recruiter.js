const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const recruiterSchema = mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  entreprise: { type: String, required: true },
  role: { type: String, default: "recruiter" },
  taille: { type: String },
  anneeCreation: { type: Number },
  siteWeb: { type: String },
  localisation: { type: String },
  logo: { type: String },
  secteur: { type: String },
  date: { type: Date, default: Date.now },
  isVerified: { type: Boolean, default: false },
  resetOtp: { type: String },
  resetOtpExpires: { type: Date },
});

recruiterSchema.pre("save", async function (next) {
  if (!this.isModified("password")) {
    return next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

recruiterSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model("Recruiter", recruiterSchema);
