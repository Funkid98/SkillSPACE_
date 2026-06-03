const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const {
  registerRecruiter,
  authRecruiter,
  verifyRecruiterSignupOtp,
  getRecruiterProfile,
  updateRecruiterProfile,
  googleSignInForRecruiter,
  githubSignInForRecruiter,
  checkRecruiterEmailExists,
  contactCandidate,
  receiveNotification,
  getNotifications,
  markNotificationRead,
  handleApplicationDecision,
  deleteNotification,
  clearAllNotifications,
  setOtp,
  verifyOtp,
  resetPassword,
  deleteRecruiterAccount,
  googleReauth,
} = require("../controllers/recruiter.controller");
const { protect } = require("../middleware/auth-middleware");

// Multer Storage Configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "public/uploads");
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});

const upload = multer({ storage });

// Public routes
router.post("/register", registerRecruiter);
router.post("/login", authRecruiter);
router.post("/verify-signup", verifyRecruiterSignupOtp);
router.post("/google", googleSignInForRecruiter);
router.post("/github", githubSignInForRecruiter);
router.get("/exists/:email", checkRecruiterEmailExists);

// Protected routes
router.get("/profile", protect, getRecruiterProfile);
router.put("/profile", protect, updateRecruiterProfile);
router.delete("/profile", protect, deleteRecruiterAccount); // Keeping alias
router.delete("/profile/delete", protect, deleteRecruiterAccount);
router.post("/profile/google-reauth", protect, googleReauth);

// Upload logo
router.post("/upload", protect, upload.single("logo"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: "Please upload a file" });
  }
  const url = `http://localhost:5002/uploads/${req.file.filename}`;
  res.json({ url });
});

// Notifications & Contact
router.post("/contact", protect, contactCandidate);
router.post("/internal/notify", receiveNotification);
router.get("/notifications", protect, getNotifications);
router.put("/notifications/:id/read", protect, markNotificationRead);
router.delete("/notifications/:id", protect, deleteNotification);
router.delete("/notifications/clear/all", protect, clearAllNotifications);
router.post("/notifications/decision", protect, handleApplicationDecision);

// Internal OTP routes
router.post("/internal/set-otp", setOtp);
router.post("/internal/verify-otp", verifyOtp);
router.post("/internal/reset-password", resetPassword);
// Public password reset routes (used by ChangePasswordDialog)
router.post("/forgot-password", setOtp);
router.post("/verify-otp", verifyOtp);
router.post("/reset-password", resetPassword);

module.exports = router;
