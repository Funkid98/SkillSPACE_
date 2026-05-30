const mongoose = require("mongoose");

const applicationSchema = mongoose.Schema(
  {
    candidateId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    offerId: { type: String, required: true },
    recruiterId: { type: String, required: true },
    status: {
      type: String,
      enum: ["PENDING", "ACCEPTED", "REJECTED", "INTERVIEW_PLANNED"],
      default: "PENDING",
    },
    interviewDate: { type: String },
    interviewTime: { type: String },
    meetingLink: { type: String },
    rejectionReason: { type: String },
  },
  { timestamps: true },
);

module.exports = mongoose.model("Application", applicationSchema);
