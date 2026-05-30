const mongoose = require("mongoose");

const matchSchema = new mongoose.Schema(
  {
    candidateId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    offerId: { type: mongoose.Schema.Types.ObjectId, required: true },
    score: { type: Number, required: true },
    matchingSkills: { type: Number, default: 0 },
    totalSkills: { type: Number, default: 0 },
    analysis: { type: String, default: "" },
    recommendation: { type: String, default: "" },
    matchedSkills: { type: [String], default: [] },
    missingSkills: { type: [String], default: [] },
    internalFormationId: { type: String, default: null },
    candidateSkillsSnapshot: { type: String, default: "" },
    offerRequirementsSnapshot: { type: String, default: "" },
    status: {
      type: String,
      enum: ["PRELIMINARY", "ANALYSING", "COMPLETED", "FAILED"],
      default: "PRELIMINARY",
    },
  },
  { timestamps: true },
);

// Ensure unique index so a candidate only has one match per offer
matchSchema.index({ candidateId: 1, offerId: 1 }, { unique: true });

module.exports = mongoose.model("Match", matchSchema);
