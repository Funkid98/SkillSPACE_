const mongoose = require("mongoose");

const interviewHistorySchema = new mongoose.Schema({
  candidateId: { type: String, required: true },
  roleTitle: { type: String },
  globalScore: { type: Number },
  emotionalState: { type: String },
  analysis: { type: Object },
  conversation: [
    {
      role: { type: String, enum: ["user", "assistant"] },
      text: { type: String },
      audioUrl: { type: String, default: null },
      vocalMetrics: { type: Object, default: null },
    },
  ],
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model("InterviewHistory", interviewHistorySchema);
