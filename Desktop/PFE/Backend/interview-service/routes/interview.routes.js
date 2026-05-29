const express = require('express');
const router = express.Router();
const multer = require('multer');
const fs = require('fs');
const interviewController = require('../controllers/interview.controller');

if (!fs.existsSync('uploads/')) {
  fs.mkdirSync('uploads/');
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/')
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9)
    const ext = file.originalname.split('.').pop();
    cb(null, file.fieldname + '-' + uniqueSuffix + '.' + ext)
  }
});
const upload = multer({ storage: storage });

// Initialize a new simulation session
router.post('/start', interviewController.startSimulation);

// Send message to AI and get response (text or audio)
router.post('/chat', upload.single('audio'), interviewController.chatWithAI);

// Finish simulation and get final score analysis
router.post('/finish', interviewController.finishSimulation);

// Get interview history
router.get('/history/:candidateId', interviewController.getHistory);

// Transcribe audio file
router.post('/transcribe', upload.single('audio'), interviewController.transcribeAudio);

module.exports = router;
