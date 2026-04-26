const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth-middleware');
const { generateQuizHandler, evaluateQuizHandler } = require('../controllers/quiz-controller');

router.post('/generate', auth, generateQuizHandler);
router.post('/evaluate', auth, evaluateQuizHandler);

module.exports = router;
