require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const path = require("path");
const interviewRoutes = require("./routes/interview.routes");

const app = express();

const allowedOrigins = (process.env.ALLOWED_ORIGINS || "http://localhost:3000")
  .split(",")
  .map((o) => o.trim());
app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error(`CORS blocked: ${origin}`));
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }),
);
app.use(express.json());
app.use(cookieParser());

// Serve uploaded audio files
app.use(
  "/api/interview/uploads/audio",
  express.static(path.join(__dirname, "uploads", "audio")),
);

// Routes
app.use("/api/interview", interviewRoutes);

// Database connection
mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => console.log("Connected to MongoDB (interview)"))
  .catch((err) => console.error("MongoDB connection error:", err));

const PORT = process.env.PORT || 5005;

app.listen(PORT, () => {
  console.log(`Interview Service running on port ${PORT}`);
});
