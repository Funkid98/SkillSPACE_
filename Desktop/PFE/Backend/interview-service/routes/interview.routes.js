const express = require('express');
const router = express.Router();
const interviewController = require('../controllers/interview.controller');

// Initialize a new simulation session
router.post('/start', interviewController.startSimulation);

// Send message to AI and get response
router.post('/chat', interviewController.chatWithAI);

// Finish simulation and get final score analysis
router.post('/finish', interviewController.finishSimulation);

module.exports = router;
