const { generateQuiz, evaluateQuiz } = require('../services/ai-service');

const generateQuizHandler = async (req, res) => {
  try {
    const { skill, level } = req.body;
    if (!skill || !level) {
      return res.status(400).json({ message: 'Skill and level are required' });
    }

    const quiz = await generateQuiz(skill, level);
    res.status(200).json(quiz);
  } catch (error) {
    console.error('Error generating quiz:', error);
    res.status(500).json({ message: 'Server error generating quiz' });
  }
};

const evaluateQuizHandler = async (req, res) => {
  try {
    const { skill, claimedLevel, qna } = req.body;
    if (!skill || !claimedLevel || !qna) {
      return res.status(400).json({ message: 'Skill, claimedLevel, and qna are required' });
    }

    const result = await evaluateQuiz(skill, claimedLevel, qna);
    res.status(200).json(result);
  } catch (error) {
    console.error('Error evaluating quiz:', error);
    res.status(500).json({ message: 'Server error evaluating quiz' });
  }
};

module.exports = { generateQuizHandler, evaluateQuizHandler };
