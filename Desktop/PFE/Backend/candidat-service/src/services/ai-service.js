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

        IMPORTANT: The candidate has precise skill proficiency levels (0% to 100%). You MUST factor these into the score:
        - A skill at 80%+ (Advanced) earns full credit.
        - A skill at 40-79% (Intermediate) earns 60% credit.
        - A skill at 1-39% (Beginner) earns 25% credit.
        - A missing skill earns 0%.

        Reply ONLY with JSON (no text before or after, no markdown) with these fields:
        1. matching_analysis: A 2-3 sentence narrative explaining the candidate's fit based on their skills AND proficiency levels. Do NOT use bullet lists.
        2. recommendation: Specific training recommendations for missing or insufficient skills.
        3. score: Compatibility score (0-100) based EXCLUSIVELY on the Skills_Required and the candidate's proficiency levels.
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
        content: `You are an expert technical trainer. Generate a short multiple-choice quiz of 5 questions to assess the skill '${skill}' at the '${level}' level.
        The first 4 questions should examine theoretical knowledge and practical applications.
        The 5th (last) question MUST be a problem-solving scenario where the user has to choose the correct approach or solution to a specific issue.
        Reply ONLY with JSON as an array of 5 objects.
        Expected format:
        [
          {
            "question": "Question text",
            "options": ["Option 1", "Option 2", "Option 3", "Option 4"]
          }
        ]
        Do not include the correct answer in the returned JSON. Do not include any text before or after the JSON.`
      },
      {
        role: 'user',
        content: `Generate a 5-question quiz for ${skill} at ${level} level. Remember the 5th question must be a problem solving scenario.`
      }
    ],
    temperature: 0.7,
  })

  const content = response.choices[0].message.content
  const clean = content.replace(/```json|```/g, '').trim()
  try {
    return JSON.parse(clean)
  } catch (err) {
    console.error('Groq Quiz Gen Parse Error:', err.message, 'Content:', content)
    throw new Error('Failed to generate quiz')
  }
}

const evaluateQuiz = async (skill, claimedLevel, qna) => {
  const qnaText = JSON.stringify(qna, null, 2)
  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: `You are a technical recruiter. Evaluate the candidate's answers for the skill "${skill}".
        The candidate claimed to be at the "${claimedLevel}" level.
        
        Analyze these 5 questions and answers:
        ${qnaText}

        SCORING RULES (weighted system):
        - Questions 1 to 4 are standard knowledge questions: each correct answer is worth 15 points (max 60 points total).
        - Question 5 is a PROBLEM-SOLVING scenario and is worth 40 points (max 40 points).
        - Total maximum score = 100 points.
        
        Evaluate each answer strictly and calculate the total "score".
        
        Then determine "determined_level" based on score:
        - 0-30: Beginner
        - 40-70: Intermediate
        - 80-100: Advanced
        
        Provide brief constructive "feedback" explaining the evaluation.

        Return ONLY a JSON object:
        {
          "score": number,
          "determined_level": "Beginner" | "Intermediate" | "Advanced",
          "feedback": "string"
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

module.exports = { extractSkillsFromText, matchCvWithJob, generateQuiz, evaluateQuiz }