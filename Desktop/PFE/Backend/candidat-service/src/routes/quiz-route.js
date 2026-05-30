const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth-middleware");
const {
  generateQuizHandler,
  evaluateQuizHandler,
  recommendCoursesHandler,
} = require("../controllers/quiz-controller");

router.post("/generate", auth, generateQuizHandler);
router.post("/evaluate", auth, evaluateQuizHandler);
router.post("/recommend", auth, recommendCoursesHandler);

module.exports = router;
