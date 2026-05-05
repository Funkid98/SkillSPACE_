const { generateQuiz, evaluateQuiz, getCourseRecommendationsAI } = require('../services/ai-service');
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

const recommendCoursesHandler = async (req, res) => {
  try {
    const { skill, score, claimedLevel, answersAnalysis } = req.body;
    if (!skill || score === undefined) {
      return res.status(400).json({ message: 'Skill and score are required' });
    }

    // Derive achieved level from final weighted score
    let achievedLevel = 'Beginner';
    if (score >= 80) achievedLevel = 'Advanced';
    else if (score >= 40) achievedLevel = 'Intermediate';

    // Extract wrong topics from answers_analysis for targeted recommendations
    const wrongTopics = [];
    if (Array.isArray(answersAnalysis)) {
      answersAnalysis.forEach(ans => {
        if (ans.is_correct === false && ans.question) {
          // Distill the topic from the question text (first ~60 chars)
          wrongTopics.push(ans.question.substring(0, 80));
        }
      });
    }

    // Map achieved level to French for DB query
    const levelFrMap = {
      Beginner: ['Débutant', 'Intermédiaire'],        // beginners also benefit from intro-intermediate
      Intermediate: ['Intermédiaire', 'Avancé'],       // intermediates need intermediate + advanced
      Advanced: ['Avancé', 'Intermédiaire'],           // advanced users need advanced (+ intermediate for gaps)
    };
    const relevantLevels = levelFrMap[achievedLevel] || ['Débutant'];

    let availableInternalFormations = [];
    try {
      const axios = require('axios');
      // Fetch ALL formations for this skill from the trainer service
      const response = await axios.get(`http://127.0.0.1:5004/api/formateur/all-formations`, {
        params: { query: skill }
      });
      const allFormations = response.data || [];

      // Pre-filter by relevant levels so AI gets a meaningful, scoped list
      availableInternalFormations = allFormations.filter(f =>
        relevantLevels.includes(f.level)
      );

      // Fallback: if filter returns nothing, send all (AI will still reason about level)
      if (availableInternalFormations.length === 0) {
        availableInternalFormations = allFormations;
      }

      console.log(`[Recommend] ${skill} (${score}% - ${achievedLevel}): ${availableInternalFormations.length} internal formations in scope (levels: ${relevantLevels.join(', ')})`);
    } catch (err) {
      console.error('Error fetching internal formations from formateur-service:', err.message);
    }

    // Ask AI to pick the best formations using rich personalization context
    const aiResult = await getCourseRecommendationsAI(
      skill,
      score,
      claimedLevel || achievedLevel,
      wrongTopics,
      availableInternalFormations
    );

    // Map AI-selected internal IDs back to full formation objects
    let finalInternal = [];
    if (aiResult.internal && Array.isArray(aiResult.internal)) {
      aiResult.internal.forEach(aiMatch => {
        const fullFormation = availableInternalFormations.find(
          f => String(f._id) === String(aiMatch._id)
        );
        if (fullFormation) {
          finalInternal.push({
            ...fullFormation,
            ai_reason: aiMatch.reason,
          });
        }
      });
    }

    res.status(200).json({
      level_determined: achievedLevel,
      internal_formations: finalInternal,
      external_formations: (aiResult.external || []).map(e => ({
        ...e,
        ai_reason: e.why,  // expose the "why" as ai_reason for frontend consistency
      })),
    });
  } catch (error) {
    console.error('Error recommending courses:', error);
    res.status(500).json({ message: 'Server error recommending courses' });
  }
};

module.exports = { generateQuizHandler, evaluateQuizHandler, recommendCoursesHandler };