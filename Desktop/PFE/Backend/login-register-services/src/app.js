const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const express = require("express");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const connectDB = require("./config/db");
const authRoutes = require("./routes/authRoutes");

const app = express();

// ── MongoDB ──────────────────────────────────────────────────────────────────
connectDB();

// ── CORS ─────────────────────────────────────────────────────────────────────
// IMPORTANT: credentials:true is required so the browser sends/receives cookies
const allowedOrigins = (process.env.ALLOWED_ORIGINS || "http://localhost:3000")
  .split(",")
  .map((o) => o.trim());

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (curl, Postman, server-to-server)
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error(`CORS blocked: ${origin}`));
    },
    credentials: true, // ← allows cookies to be sent/received
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    exposedHeaders: ["Set-Cookie"],
  }),
);

// ── Body / Cookie parsers ─────────────────────────────────────────────────────
app.use(express.json());
app.use(cookieParser()); // ← makes req.cookies available in every route

// ── Routes ───────────────────────────────────────────────────────────────────
app.use("/api/auth", authRoutes);

// ── Health check ─────────────────────────────────────────────────────────────
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "SkillSpace API is running!",
    version: "2.0.0",
  });
});

// ── 404 ──────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route non trouvée." });
});

// ── Global error handler ─────────────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res
    .status(500)
    .json({ success: false, message: "Erreur serveur.", error: err.message });
});

// ── Start ─────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5001;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Serveur démarré sur le port ${PORT}`);
  console.log(`📡 http://localhost:${PORT}`);
  console.log(
    `🔒 Cookie auth enabled | Allowed origins: ${allowedOrigins.join(", ")}`,
  );
});
