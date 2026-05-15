const mongoose = require('mongoose');

const interviewHistorySchema = new mongoose.Schema({
  candidateId: { type: String, required: true },
  roleTitle: { type: String },
  globalScore: { type: Number },
  emotionalState: { type: String },
  analysis: { type: Object },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('InterviewHistory', interviewHistorySchema);
