const { generateQuiz, evaluateQuiz } = require('../services/ai-service');
const User = require('../models/candidat');
const { runBackgroundMatchForCandidate } = require('../services/background-matcher');

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
    const userId = req.userId;

    if (!skill || !claimedLevel || !qna) {
      return res.status(400).json({ message: 'Skill, claimedLevel, and qna are required' });
    }

    const result = await evaluateQuiz(skill, claimedLevel, qna);
    
    // Manually calculate/verify score from answers_analysis to ensure accuracy
    if (result.answers_analysis && Array.isArray(result.answers_analysis)) {
      let calculatedScore = 0;
      result.answers_analysis.forEach((ans, index) => {
        if (ans.is_correct === true) {
          if (index < 4) calculatedScore += 15; // Q1-Q4: 15pts each
          else calculatedScore += 40; // Q5: 40pts
        }
      });
      result.score = calculatedScore;
    }

    let rawScore = result.score || 0;
    let score = 0;
    if (claimedLevel === 'Beginner') {
      score = Math.round(rawScore * 0.4); // Max 40%
    } else if (claimedLevel === 'Intermediate') {
      score = Math.round(rawScore * 0.8); // Max 80%
    } else {
      score = rawScore; // Max 100%
    }
    score = Math.max(0, Math.min(100, (Math.round(score / 5) * 5)));

    // Update user skill in database
    const user = await User.findById(userId);
    if (user) {
      const skillIndex = user.skills.findIndex(s => s.name === skill);
      if (skillIndex > -1) {
        user.skills[skillIndex].percent = score;
      } else {
        user.skills.push({ name: skill, percent: score });
      }
      await user.save();
      
      // Trigger Re-analysis
      console.log(`[Quiz] Skill ${skill} updated to ${score}%. Triggering re-analysis for ${user.prenom}`);
      runBackgroundMatchForCandidate(user._id).catch(e => console.error("BG match error after quiz:", e));
    }

    res.status(200).json({ ...result, updated_score: score });
  } catch (error) {
    console.error('Error evaluating quiz:', error);
    res.status(500).json({ message: 'Server error evaluating quiz' });
  }
};

module.exports = { generateQuizHandler, evaluateQuizHandler };
