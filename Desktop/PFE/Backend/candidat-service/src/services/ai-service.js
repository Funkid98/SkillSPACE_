const Groq = require('groq-sdk')

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY })

const extractSkillsFromText = async (cvText) => {
  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: `You are a CV analyzer. Extract all information from the CV.
        Return ONLY this JSON, no extra text, no markdown:
        {
          "prenom": "first name",
          "nom": "last name",
          "jobTitle": "current or desired job title ex: Frontend Developer",
          "telephone": "phone number",
          "localisation": "city, country",
          "bio": "short professional summary",
          "skills": ["React", "Python", "MongoDB"],
          "projects": ["Project 1", "Project 2", "Project 3"],
          "education": "highest degree",
          "experience_years": 0,
          "languages": ["French", "English"]
        }`
      },
      {
        role: 'user',
        content: `Analyze this CV:\n\n${cvText}`
      }
    ],
    temperature: 0.2,
  })

  const content = response.choices[0].message.content
  const clean = content.replace(/```json|```/g, '').trim()
  return JSON.parse(clean)
}

const matchCvWithJob = async (cvText, jobDescription, candidateSkills = []) => {
  // Build a structured skill list with explicit percent proficiency for the AI
  const skillsWithLevel = candidateSkills.map(s => {
    const name = typeof s === 'string' ? s : s.name;
    const percent = typeof s === 'string' ? 33 : (s.percent || 33);
    const level = percent >= 80 ? 'Advanced' : percent >= 40 ? 'Intermediate' : 'Beginner';
    return `${name}: ${percent}% (${level})`;
  }).join('\n');

  const skillsSection = skillsWithLevel
    ? `\n\nCANDIDATE SKILL PROFICIENCY (use these exact scores in your compatibility analysis):\n${skillsWithLevel}`
    : '';

  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: `You are an expert technical recruiter. Your analysis and compatibility score must be based EXCLUSIVELY on the required skills (Skills_Required) of the job posting, ignoring everything else.

        IMPORTANT: The candidate has precise skill proficiency levels (0% to 100%). You MUST calculate the compatibility score exactly as follows:
        1. Identify all required skills specified in the job posting (let's say there are 'N' required skills in total).
        2. For each required skill, check the candidate's proficiency and assign a credit factor:
           - A skill at 80%+ (Advanced) earns full credit (1.0).
           - A skill at 40%-79% (Intermediate) earns 60% credit (0.6).
           - A skill at 1%-39% (Beginner) earns 25% credit (0.25).
           - A missing skill earns no credit (0.0).
        3. Sum up the credits earned across all N required skills.
        4. Calculate the compatibility score using the formula: Score = (Sum of Credits / N) * 100.
        5. Round the resulting score to the nearest integer (between 0 and 100).

        Reply ONLY with JSON (no text before or after, no markdown) with these fields:
        1. matching_analysis: (MUST be in French) A 2-3 sentence narrative explaining the candidate's fit based on their skills AND proficiency levels. Do NOT use bullet lists.
        2. recommendation: (MUST be in French) Specific training recommendations for missing or insufficient skills.
        3. score: Compatibility score (0-100) calculated EXCLUSIVELY using the formula described above.
        4. matched_skills: List of skill names from the candidate that match the job's Skills_Required.
        5. missing_skills: EXACT list of skills the candidate is missing or underqualified in, based EXCLUSIVELY on the Skills_Required.`
      },
      {
        role: 'user',
        content: `CANDIDATE PROFILE:\n${cvText}${skillsSection}\n\nJOB POSTING:\n${jobDescription}`
      }
    ],
    temperature: 0.1,
  })

  const content = response.choices[0].message.content
  const clean = content.replace(/```json|```/g, '').trim()
  try {
    const result = JSON.parse(clean)
    result.status = 'COMPLETED'
    return result
  } catch (err) {
    console.error('Groq Match Parse Error:', err.message, 'Content:', content)
    return { status: 'FAILED', error: err.message }
  }
}

const generateQuiz = async (skill, level) => {
  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: `You are a technical quiz generator using the Dreyfus Skill Acquisition Model.
        
        Generate questions adapted to the "${level}" Dreyfus stage:
        
        IF level = "Beginner":
          - Q1–Q4: basic rule recall & fundamental knowledge
          - Q5: slightly complex beginner problem-solving scenario
        
        IF level = "Intermediate":
          - Q1–Q4: pattern recognition & applied knowledge in context
          - Q5: real-world problem-solving scenario
        
        IF level = "Advanced":
          - Q1–Q4: deep knowledge, edge cases & system design
          - Q5: complex system-level problem-solving scenario
        
        RULES:
        - Q5 MUST always be a practical problem-solving scenario
        - Questions must be strictly adapted to the "${level}" level
        - No overlap between levels
        
        RETURN ONLY THIS JSON — NO EXTRA TEXT:
        {
          "skill": "string",
          "level": "Beginner" | "Intermediate" | "Advanced",
          "questions": [
            {
              "id": number,
              "question": "string",
              "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
              "correct_answer": "string",
              "dreyfus_stage_tested": "Beginner" | "Intermediate" | "Advanced"
            }
          ]
        }`
      },
      {
        role: 'user',
        content: `Generate a 5-question quiz for the skill "${skill}" at "${level}" level.
                  Q5 must be a problem-solving scenario.`
      }
    ],
    temperature: 0.7,
  })

  const content = response.choices[0].message.content
  const clean = content.replace(/```json|```/g, '').trim()
  try {
    return JSON.parse(clean)
  } catch (err) {
    console.error('Quiz Gen Error:', err.message)
    throw new Error('Failed to generate quiz')
  }
}
const evaluateQuiz = async (skill, claimedLevel, qna) => {
  // The AI already returns a computed score, but we keep a deterministic fallback.
  // This helper can be used elsewhere to recalculate the score from raw answers if needed.
  const calculateScore = (qnaResults) => {
    // qnaResults is an array of 5 objects with { is_correct: boolean }
    let score = 0;
    // First four theoretical questions (index 0‑3)
    for (let i = 0; i < 4; i++) {
      if (qnaResults[i] && qnaResults[i].is_correct) {
        score += 15;
      }
    }
    // Fifth problem‑solving scenario (index 4)
    if (qnaResults[4] && qnaResults[4].is_correct) {
      score += 40;
    }
    return score; // Returns 0‑100
  };

  const qnaText = JSON.stringify(qna, null, 2)
  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: `You are a technical recruiter evaluating candidates using 
        the Dreyfus Skill Acquisition Model (Dreyfus & Dreyfus, Berkeley 1980).
        Applied in a simplified 3-stage framework adapted for technical recruitment.

        Candidate claimed level: "${claimedLevel}"
        Skill being evaluated: "${skill}"

        Questions and Answers:
        ${qnaText}

        ═══════════════════════════════════════════
        STEP 1 — SCORING (Dreyfus-Weighted Rubric)
        ═══════════════════════════════════════════
        The quiz has 3 levels, each with its own questions.
        Questions are evaluated based on the level they belong to.

        CRITICAL: Scoring is strictly binary per question. NO partial or intermediate points allowed.
        - Correct Q1–Q4 = 15 pts each (0 pts if wrong) -> max 60 pts
        - Correct Q5    = 40 pts (0 pts if wrong)       -> max 40 pts
        - Total max     = 100 pts
        - All wrong     = 0 pts

        ═══════════════════════════════════════════
        STEP 2 — SCORE BRACKETS (Strict Boundaries)
        ═══════════════════════════════════════════
        Regardless of the claimed level, the score dictates the technical capability:
        - 0–39   → Beginner level capabilities
        - 40–79  → Intermediate level capabilities
        - 80–100 → Advanced level capabilities

        ═══════════════════════════════════════════
        STEP 3 — COHERENCE CHECK & CROSS-EVALUATION
        ═══════════════════════════════════════════
        Compare the score achieved against what the candidate claimed:

        IF claimedLevel = "Advanced":
          - score 80–100 → determined_level: "Advanced"     | level_match: "confirmed"
          - score 40–79  → determined_level: "Intermediate" | level_match: "overrated"
          - score 0–39   → determined_level: "Beginner"     | level_match: "critical_mismatch"

        IF claimedLevel = "Intermediate":
          - score 80–100 → determined_level: "Advanced"     | level_match: "underrated"
          - score 40–79  → determined_level: "Intermediate" | level_match: "confirmed"
          - score 0–39   → determined_level: "Beginner"     | level_match: "overrated"

        IF claimedLevel = "Beginner":
          - score 80–100 → determined_level: "Intermediate" | level_match: "underrated"
          - score 40–79  → determined_level: "Beginner"     | level_match: "confirmed"
          - score 0–39   → determined_level: "Beginner"     | level_match: "confirmed"

        ═══════════════════════════════════════════
        STEP 4 — FEEDBACK RULES (Dreyfus-based)
        ═══════════════════════════════════════════
        Write the feedback string in FRENCH. Keep it professional, constructive, and directly mapped to the level_match:
        - confirmed + Beginner     → encourage to strengthen fundamentals
        - confirmed + Intermediate → encourage to tackle Advanced challenges  
        - confirmed + Advanced     → validate expertise, highlight mastery
        - underrated               → highlight unexpected strengths, encourage to aim higher
        - overrated                → mention gap kindly, suggest going back to lower level
        - critical_mismatch        → honest, flag major gap, recommend Beginner level restart

        ═══════════════════════════════════════════
        RETURN ONLY THIS JSON — NO EXTRA TEXT
        ═══════════════════════════════════════════
        {
          "score": number,
          "claimed_level": "Beginner" | "Intermediate" | "Advanced",
          "determined_level": "Beginner" | "Intermediate" | "Advanced",
          "level_match": "confirmed" | "overrated" | "underrated" | "critical_mismatch",
          "feedback": "string in French",
          "answers_analysis": [
            {
              "question": "string",
              "user_answer": "string",
              "is_correct": boolean,
              "dreyfus_stage_tested": "Beginner" | "Intermediate" | "Advanced",
              "correct_answer": "string"
            }
          ]
        }`
      },
      {
        role: 'user',
        content: `Evaluate the candidate's level based on these answers.`
      }
    ],
    temperature: 0.2,
    response_format: { type: 'json_object' },
  })

  const content = response.choices[0].message.content
  try {
    return JSON.parse(content)
  } catch (err) {
    console.error('Groq Quiz Eval Parse Error:', err.message, 'Content:', content)
    return { determined_level: claimedLevel, feedback: "Analysis failed." }
  }
}

/**
 * Generates deeply personalized course recommendations.
 *
 * @param {string}   skill            - The skill name (e.g. "Python")
 * @param {number}   score            - Final computed score 0-100 (already level-weighted)
 * @param {string}   claimedLevel     - The level the user self-declared: 'Beginner' | 'Intermediate' | 'Advanced'
 * @param {Array}    wrongTopics      - List of topics/questions the user got wrong (from answers_analysis)
 * @param {Array}    internalFormations - Formations fetched from internal DB
 */
const getCourseRecommendationsAI = async (skill, score, claimedLevel, wrongTopics, internalFormations) => {

  // Derive achieved level from score
  let achievedLevel = 'Beginner';
  if (score >= 80) achievedLevel = 'Advanced';
  else if (score >= 40) achievedLevel = 'Intermediate';

  // Build a nuanced skill gap description
  const gapDescription = buildGapDescription(skill, score, claimedLevel, achievedLevel, wrongTopics);

  // Build internal formations list for AI (only relevant level range)
  const internalJson = JSON.stringify(
    internalFormations.map(f => ({
      id: f._id,
      title: f.title,
      level: f.level,          // 'Débutant' | 'Intermédiaire' | 'Avancé'
      description: f.description || '',
      tags: (f.tags || []).join(', '),
      category: f.category || '',
    }))
  );

  const promptText = `
## Learner Profile
- Skill: "${skill}"
- Self-declared level: ${claimedLevel}
- Quiz score: ${score}/100
- Achieved level (from score): ${achievedLevel}
- Skill gap analysis: ${gapDescription}
- Topics they struggled with: ${wrongTopics.length > 0 ? wrongTopics.join('; ') : 'None identified'}

## Task
You are a learning advisor. Your job is to recommend the MOST PERSONALIZED courses for this exact learner profile.

CRITICAL RULES:
1. A ${claimedLevel} at ${score}% is NOT the same as an ${achievedLevel} at ${score}%.
   - ${claimedLevel} ${score}% → They overestimated themselves → They need foundational reinforcement at ${achievedLevel} level.
   - Their weak topics MUST drive the recommendations.
2. Do NOT recommend courses that are too advanced or too basic for their actual gap.
3. For internal formations: evaluate BOTH the level AND the description/tags to match their specific gaps.
4. For external formations: generate highly specific courses targeting EXACTLY the weak topics found.

## Available Internal Formations
${internalJson || '[]'}

## Instructions
Select up to 3 internal formations that best address the learner's SPECIFIC gaps.
Then generate external course recommendations to fill any remaining gaps (total: at least 3 recommendations).

Return ONLY valid JSON, no markdown:
{
  "internal": [
    {
      "_id": "exact id from list",
      "title": "exact title",
      "trainerName": "trainer name",
      "reason": "(MUST be in French) Specific 1-sentence explanation referencing their score (${score}%) AND their weak topics"
    }
  ],
  "external": [
    {
      "title": "Very specific course title targeting their weak topics",
      "platform": "Coursera | Udemy | YouTube | edX | LinkedIn Learning",
      "url": "MUST be a valid, real-world URL (e.g., https://www.udemy.com/course/name-of-course/). NO placeholder links.",
      "type": "Course | Workshop | Tutorial | Bootcamp",
      "why": "(MUST be in French) 1-sentence explanation of why this targets their specific gap"
    }
  ]
}
CRITICAL URL RULES:
- NEVER guess specific course slugs or video IDs. They cause 404 errors.
- For YouTube: use https://www.youtube.com/results?search_query=react+[topic]+tutorial
- For Udemy: use https://www.udemy.com/courses/search/?q=react+[topic]
- For Coursera: use https://www.coursera.org/search?query=react+[topic]

Example: If the topic is "Context API", the url MUST be: https://www.udemy.com/courses/search/?q=react+context+api
- NEVER return "example.com" or "course-link-here". If unsure, use a search results link as shown above.`;

  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: `You are a highly specialized learning advisor. You MUST tailor every recommendation to the learner's exact skill gap, score, and wrong topics. Return ONLY valid JSON with no extra text or markdown.`
      },
      {
        role: 'user',
        content: promptText
      }
    ],
    temperature: 0.3,
  });

  const content = response.choices[0].message.content;
  const clean = content.replace(/```json|```/g, '').trim();
  try {
    return JSON.parse(clean);
  } catch (err) {
    console.error('Groq Course Recommendation Parse Error:', err.message, 'Content:', content);
    return { internal: [], external: [] };
  }
}

/**
 * Builds a human-readable gap description based on score context.
 * A 55% Beginner ≠ 55% Intermediate — this captures that difference.
 */
function buildGapDescription(skill, score, claimedLevel, achievedLevel, wrongTopics) {
  const levelMap = { Beginner: 1, Intermediate: 2, Advanced: 3 };
  const claimedRank = levelMap[claimedLevel] || 1;
  const achievedRank = levelMap[achievedLevel] || 1;

  if (claimedRank > achievedRank) {
    return `The learner claimed ${claimedLevel} but only achieved ${achievedLevel} level (${score}%). ` +
      `This means they have significant gaps in ${skill} concepts that should be at ${achievedLevel} level. ` +
      `Recommend courses that consolidate ${achievedLevel}-level ${skill} fundamentals, ` +
      `especially around: ${wrongTopics.slice(0, 3).join(', ') || 'core concepts'}.`;
  } else if (claimedRank === achievedRank) {
    if (score >= 70) {
      return `The learner is solid at ${achievedLevel} level (${score}%) and is ready to advance. ` +
        `Recommend courses that bridge ${achievedLevel} to ${achievedLevel === 'Beginner' ? 'Intermediate' : 'Advanced'} level, ` +
        `particularly covering: ${wrongTopics.slice(0, 3).join(', ') || 'advanced topics'}.`;
    } else {
      return `The learner is at ${achievedLevel} level but scored only ${score}%, indicating gaps. ` +
        `Recommend courses to reinforce ${achievedLevel}-level ${skill}, ` +
        `focusing on: ${wrongTopics.slice(0, 3).join(', ') || 'weak areas'}.`;
    }
  } else {
    return `The learner exceeded their ${claimedLevel} expectation and is at ${achievedLevel} (${score}%). ` +
      `Recommend advanced ${achievedLevel}-level courses to leverage their strong foundation in ${skill}.`;
  }
}

const generateCoachAdvice = async (candidate) => {
  const profileSummary = `
  - Prenom: ${candidate.prenom}
  - Nom: ${candidate.nom}
  - Job Title: ${candidate.jobtitle || 'Not specified'}
  - Skills: ${(candidate.skills || []).map(s => typeof s === 'string' ? s : s.name).join(', ')}
  - Bio: ${candidate.bio || 'Empty'}
  - Projects: ${(candidate.projects || []).join(', ')}
  - Localisation: ${candidate.localisation || 'Not specified'}
  - Secteur: ${candidate.sector || 'Not specified'}
  `;

  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: `You are an expert AI Career Coach. Your goal is to analyze a candidate's profile, find what's missing, and provide a unique, motivating advice for the day.
        
        Analyze these areas:
        - Profile completeness (Bio, Job Title, Localisation)
        - Skills depth (if they have less than 5 skills, it's a gap)
        - Projects (if empty, it's a major gap)
        - Sector alignment
        
        Return ONLY a JSON object with:
        1. advice: A short (1-2 sentences), highly motivational and unique advice for today, in French. Avoid generic phrases.
        `
      },
      {
        role: 'user',
        content: `Today's Date: ${new Date().toLocaleDateString('fr-FR')}
        Analyze this candidate profile and give coach advice:\n${profileSummary}`
      }
    ],
    temperature: 0.7,
    response_format: { type: 'json_object' },
  })

  const content = response.choices[0].message.content
  try {
    return JSON.parse(content)
  } catch (err) {
    console.error('Groq Coach Advice Parse Error:', err.message)
    return {
      advice: "Continuez à persévérer, chaque effort vous rapproche de votre succès !"
    }
  }
}

module.exports = { extractSkillsFromText, matchCvWithJob, generateQuiz, evaluateQuiz, getCourseRecommendationsAI, generateCoachAdvice }