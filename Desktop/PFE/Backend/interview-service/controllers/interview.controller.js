const Groq = require('groq-sdk');

const groq = new Groq({
  apiKey: "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",
});

exports.startSimulation = async (req, res) => {
  try {
    const { role } = req.body;
    const jobTitle = role || 'Développeur';

    res.status(200).json({
      success: true,
      message: 'Simulation started successfully',
      initialMessage: `Bonjour et bienvenue ! Je suis votre recruteur pour le poste de ${jobTitle}. Parlez-moi d'un projet dont vous êtes particulièrement fier.`
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.chatWithAI = async (req, res) => {
  try {
    const { message, roleTitle, history = [] } = req.body;

    // Construct the detailed system prompt
    const systemPrompt = `You are Sophie Martin, an experienced hiring manager conducting a realistic job interview.

**Role & Context:**
* Position: ${roleTitle}
* Company type: Tech Company
* Candidate level: Junior/Mid-level

**Interview Style:**
* Be professional, neutral, and slightly challenging (like a real interviewer).
* Ask one question at a time.
* Wait for the candidate's answer before asking the next question.
* Ask follow-up questions based on the candidate's responses (dig deeper when needed).
* Occasionally challenge unclear or weak answers.
* Do NOT answer for the candidate.
* Do NOT give feedback until the interview is finished.
* Keep the experience as realistic as possible.
* Reply in French.`;

    // Map frontend history to Groq format
    const formattedHistory = history.map(msg => ({
      role: msg.isUser ? "user" : "assistant",
      content: msg.text
    }));

    const chatCompletion = await groq.chat.completions.create({
      messages: [
        { role: "system", content: systemPrompt },
        ...formattedHistory,
        { role: "user", content: message }
      ],
      model: "llama-3.3-70b-versatile",
      temperature: 0.7,
      max_tokens: 250,
    });

    const aiResponse = chatCompletion.choices[0]?.message?.content || "C'est intéressant. Pourriez-vous détailler un peu plus ?";

    res.status(200).json({
success: true,
  reply: aiResponse
    });
  } catch (error) {
  console.error(error);
  res.status(500).json({ success: false, message: error.message });
}
};

exports.finishSimulation = async (req, res) => {
  try {
    const { history = [], roleTitle } = req.body;
    
    if (history.length === 0) {
      return res.status(400).json({ success: false, message: "No conversation history provided for evaluation." });
    }

    const transcript = history.map(msg => `${msg.isUser ? 'Candidat' : 'Recruteur'}: ${msg.text}`).join('\n');

    const evaluationPrompt = `You are an expert HR evaluator. Review the following job interview transcript for a ${roleTitle} position.
Based on the candidate's answers, provide a detailed evaluation in JSON format exactly matching this structure:
{
  "score": <number out of 100>,
  "emotionalState": "<a brief string describing the emotional state e.g., 'Confiant', 'Stressé', 'Calme'>",
  "analysis": {
    "stressLevel": <number out of 100, where lower is better usually, but here 100 means perfectly managed stress>,
    "selfConfidence": <number out of 100>,
    "clarity": <number out of 100>,
    "engagement": <number out of 100>
  },
  "skills": {
    "clarity": <number out of 100>,
    "relevance": <number out of 100>,
    "structure": <number out of 100>
  },
  "improvements": [
    {
      "title": "<Short title of improvement>",
      "description": "<Detailed description and example of a better answer for one of the weak responses>"
    }
  ]
}
Make sure the improvements array has exactly 4 items. Write all text responses in French. Do NOT wrap the JSON in Markdown formatting like \`\`\`json. Just return the raw JSON object.

Transcript:
${transcript}`;

    const chatCompletion = await groq.chat.completions.create({
      messages: [
        { role: "system", content: "You output raw JSON only." },
        { role: "user", content: evaluationPrompt }
      ],
      model: "llama-3.3-70b-versatile",
      temperature: 0.2,
      max_tokens: 1000,
    });
    
    let evaluationData;
    try {
      const responseText = chatCompletion.choices[0]?.message?.content || "{}";
      // Clean up markdown if AI still added it
      const cleanedText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
      evaluationData = JSON.parse(cleanedText);
    } catch (e) {
      console.error("Failed to parse AI evaluation:", e);
      // Fallback
      evaluationData = {
        score: 75,
        emotionalState: "Neutre",
        analysis: { stressLevel: 50, selfConfidence: 70, clarity: 75, engagement: 80 },
        skills: { clarity: 75, relevance: 70, structure: 65 },
        improvements: [
          { title: "Structure des réponses", description: "Utilisez la méthode STAR." },
          { title: "Précision", description: "Donnez des exemples plus concrets." },
          { title: "Confiance", description: "Affirmez davantage vos réussites." },
          { title: "Engagement", description: "Posez des questions à la fin." }
        ]
      };
    }

    res.status(200).json({
      success: true,
      ...evaluationData
    });
  } catch (error) {
    console.error("Finish simulation error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};
