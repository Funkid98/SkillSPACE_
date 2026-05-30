const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/candidat");

const hashPassword = (password) => bcrypt.hash(password, 10);

const verifyPassword = (plain, hashed) => bcrypt.compare(plain, hashed);

const createToken = (userId) =>
  jwt.sign({ sub: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || "24h",
  });

const calculateCompletion = (user) => {
  let score = 0;
  if (user.telephone) score += 10;
  if (user.localisation) score += 10;
  if (user.bio) score += 20;
  if (user.cv_path) score += 20;
  if (user.skills?.length > 0) score += 10;
  return Math.min(score, 100);
};

module.exports = {
  hashPassword,
  verifyPassword,
  createToken,
  calculateCompletion,
};
