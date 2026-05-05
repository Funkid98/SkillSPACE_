const Groq = require('groq-sdk');
const fs = require('fs');
const path = require('path');

const groq = new Groq({
  apiKey: "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",
});

exports.transcribeAudio = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: "No audio file provided." });
    }

    const { language } = req.body; // 'fr' or 'en'

    // Create transcription using Groq Whisper
    const transcription = await groq.audio.transcriptions.create({
      file: fs.createReadStream(req.file.path),
      model: "whisper-large-v3",
      language: language || 'fr',
      response_format: "json",
    });

    // Clean up temporary file
    fs.unlinkSync(req.file.path);

    res.status(200).json({
      success: true,
      text: transcription.text
    });
  } catch (error) {
    console.error("Transcription error:", error);
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

async function generateAudio(text, langCode = 'fr') {
  try {
    // Using Rachel (English) and the custom voice provided (French)
    const voiceId = langCode === 'en' ? '21m00Tcm4TlvDq8ikWAM' : 'O31r762Gb3WFygrEOGh0';
    const modelId = 'eleven_multilingual_v2';

    const url = `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Accept': 'audio/mpeg',
        'xi-api-key': 'sk_8f401235d65db4da772e3a030668e254be7099fddc623b5e',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        text: text,
        model_id: modelId,
        voice_settings: {
          stability: 0.50, // Increased to prevent the voice from breaking or sounding weird
          similarity_boost: 0.75,
          style: 0.30, // Reduced so the AI doesn't overact when reading technical lists
          use_speaker_boost: true
        }
      })
    });

    if (!response.ok) {
      console.error("ElevenLabs error:", await response.text());
      return null;
    }

    const arrayBuffer = await response.arrayBuffer();
    return Buffer.from(arrayBuffer).toString('base64');
  } catch (err) {
    console.error("ElevenLabs request failed:", err);
    return null;
  }
}

exports.startSimulation = async (req, res) => {
  try {
    const { role, language } = req.body;
    const jobTitle = role || 'Développeur';
    const langCode = language || 'fr';

    const targetLanguage = langCode === 'en' ? 'English' : 'French';
    const systemPrompt = `You are Sophie Martin, an expert hiring manager.
    You are starting a job interview for the following context: ${jobTitle}.
    Generate the VERY FIRST greeting and opening question for the candidate.
    Make it professional, welcoming, and specific to the company and role if they are provided in the context.
    Talk naturally! You can use slight hesitations or warm conversational fillers (like "Bonjour et bienvenue... Alors...").
    If the context contains a list of skills, do NOT recite them like a robotic list. Integrate them naturally into your sentence, or simply say "les compétences requises".
    IMPORTANT: You must write your ENTIRE response strictly in ${targetLanguage}. If the context contains English words, TRANSLATE them into ${targetLanguage} or adapt them so the text is 100% ${targetLanguage}.
    Do not output anything else except the spoken text.`;

    const chatCompletion = await groq.chat.completions.create({
      messages: [{ role: "system", content: systemPrompt }],
      model: "llama-3.3-70b-versatile",
      temperature: 0.7,
      max_tokens: 150,
    });

    const initialMessage = chatCompletion.choices[0]?.message?.content ||
      (langCode === 'en' ? `Hello and welcome! Let's start the interview for ${jobTitle}. Tell me about yourself.`
        : `Bonjour et bienvenue ! Commençons l'entretien pour le poste de ${jobTitle}. Parlez-moi de vous.`);

    const audioBase64 = await generateAudio(initialMessage, langCode);

    res.status(200).json({
      success: true,
      message: 'Simulation started successfully',
      initialMessage: initialMessage,
      audioBase64: audioBase64
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.chatWithAI = async (req, res) => {
  try {
    const { message, roleTitle, history = [] } = req.body;
    const langCode = req.body.language || 'fr';
    const langString = langCode === 'en' ? 'English' : 'French';

    // Construct the detailed system prompt
    const systemPrompt = `You are Sophie Martin, an experienced hiring manager conducting a realistic job interview.

**Role & Context:**
* Position Context: ${roleTitle}
* Goal: You are recruiting the candidate for the company specified in the Position Context.
* Candidate level: Junior/Mid-level

**Interview Style:**
* Be professional, neutral, and slightly challenging (like a real interviewer).
* Talk naturally as human being! Use conversational fillers occasionally (e.g., "Mmm...", "D'accord...", "Je vois...", "Alors..."). This is CRITICAL for the voice synthesizer to sound human.
* Ask one question at a time.
* Wait for the candidate's answer before asking the next question.
* Ask follow-up questions based on the candidate's responses (dig deeper when needed).
* Occasionally challenge unclear or weak answers.
* Do NOT answer for the candidate.
* Do NOT give feedback until the interview is finished.
* Keep the experience as realistic as possible.
* IMPORTANT: You must write your ENTIRE response strictly in ${langString}. If the candidate uses English technical terms, TRANSLATE them into ${langString} or adapt them naturally so the text is 100% ${langString}.`;

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
    const audioBase64 = await generateAudio(aiResponse, langCode);

    res.status(200).json({
      success: true,
      reply: aiResponse,
      audioBase64: audioBase64
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
