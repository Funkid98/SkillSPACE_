const Groq = require("groq-sdk");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const groq = new Groq({
  apiKey: "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",
});

exports.transcribeAudio = async (req, res) => {
  try {
    if (!req.file) {
      return res
        .status(400)
        .json({ success: false, message: "No audio file provided." });
    }

    const { language } = req.body; // 'fr' or 'en'

    // Create transcription using Groq Whisper
    const transcription = await groq.audio.transcriptions.create({
      file: fs.createReadStream(req.file.path),
      model: "whisper-large-v3",
      language: language || "fr",
      response_format: "json",
      prompt:
        language === "en"
          ? "Umm, mmm, hmm, uh, like, you know..."
          : "Euh, mmm, hmm, donc, alors, c'est-à-dire, d'accord...",
    });

    // Clean up temporary file
    fs.unlinkSync(req.file.path);

    res.status(200).json({
      success: true,
      text: transcription.text,
    });
  } catch (error) {
    console.error("Transcription error:", error);
    if (req.file && fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

async function generateAudio(text, langCode = "fr") {
  try {
    // Use standard default voice (George) specified by the user
    const voiceId = "JBFqnCBsd6RMkjVDRZzb";
    const modelId = "eleven_multilingual_v2";

    const url = `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`;
    const response = await fetch(url, {
      method: "POST",
      headers: {
        Accept: "audio/mpeg",
        "xi-api-key": "sk_8f401235d65db4da772e3a030668e254be7099fddc623b5e",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        text: text,
        model_id: modelId,
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.75,
          style: 0.3,
          use_speaker_boost: true,
        },
      }),
    });

    if (!response.ok) {
      console.error("ElevenLabs error:", await response.text());
      return null;
    }

    const arrayBuffer = await response.arrayBuffer();
    return Buffer.from(arrayBuffer).toString("base64");
  } catch (err) {
    console.error("ElevenLabs request failed:", err);
    return null;
  }
}

exports.startSimulation = async (req, res) => {
  try {
    const { role, language } = req.body;
    const jobTitle = role || "Développeur";
    const langCode = language || "fr";

    const targetLanguage = langCode === "en" ? "English" : "French";
    const systemPrompt = `You are Thomas Lefebvre, an expert hiring manager.
    You are starting a job interview for the following context: ${jobTitle}.
    Generate the VERY FIRST greeting and opening question for the candidate.
    Make it professional, welcoming, and specific to the company and role if they are provided in the context.
    Talk naturally! You can use slight hesitations or warm conversational fillers (like "Bonjour et bienvenue... Alors...").
    If the context contains a list of skills, do NOT recite them like a robotic list. Integrate them naturally into your sentence, or simply say "les compétences requises".
    IMPORTANT: You must write your ENTIRE response strictly in ${targetLanguage}. If the context contains English words, TRANSLATE them into ${targetLanguage} or adapt them so the text is 100% ${targetLanguage}.
    CRITICAL: Always finish your sentences and ensure the thought is complete.
    Do not output anything else except the spoken text.`;

    const chatCompletion = await groq.chat.completions.create({
      messages: [{ role: "system", content: systemPrompt }],
      model: "llama-3.3-70b-versatile",
      temperature: 0.7,
      max_tokens: 350,
    });

    const initialMessage =
      chatCompletion.choices[0]?.message?.content ||
      (langCode === "en"
        ? `Hello and welcome! Let's start the interview for ${jobTitle}. Tell me about yourself.`
        : `Bonjour et bienvenue ! Commençons l'entretien pour le poste de ${jobTitle}. Parlez-moi de vous.`);

    const audioBase64 = await generateAudio(initialMessage, langCode);

    res.status(200).json({
      success: true,
      message: "Simulation started successfully",
      initialMessage: initialMessage,
      audioBase64: audioBase64,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.chatWithAI = async (req, res) => {
  try {
    let message = req.body.message;
    const langCode = req.body.language || "fr";
    const langString = langCode === "en" ? "English" : "French";

    // If an audio file was uploaded, transcribe it first
    let audioUrl = null;
    let vocalMetrics = null;
    if (req.file) {
      const transcription = await groq.audio.transcriptions.create({
        file: fs.createReadStream(req.file.path),
        model: "whisper-large-v3",
        language: langCode,
        response_format: "verbose_json",
        timestamp_granularities: ["word"],
        prompt:
          langCode === "en"
            ? "Umm, mmm, hmm, uh, like, you know..."
            : "Euh, mmm, hmm, donc, alors, c'est-à-dire, d'accord...",
      });
      message = transcription.text;

      // Compute vocal metrics from word-level timestamps
      if (transcription.words && transcription.words.length > 1) {
        const words = transcription.words;
        const gaps = [];
        for (let i = 1; i < words.length; i++) {
          gaps.push(words[i].start - words[i - 1].end);
        }
        const totalDuration = words[words.length - 1].end - words[0].start;
        const totalPauseTime = gaps
          .filter((g) => g > 0.3)
          .reduce((s, g) => s + g, 0);
        const speakingTime = totalDuration - totalPauseTime;

        vocalMetrics = {
          wordCount: words.length,
          totalDuration: Math.round(totalDuration * 100) / 100,
          speakingTime: Math.round(speakingTime * 100) / 100,
          wordsPerMinute:
            speakingTime > 0
              ? Math.round((words.length / speakingTime) * 60)
              : 0,
          avgPauseMs:
            gaps.length > 0
              ? Math.round(
                (gaps.reduce((s, g) => s + g, 0) / gaps.length) * 1000,
              )
              : 0,
          longPauses: gaps.filter((g) => g > 0.5).length,
          pauseRate:
            Math.round(
              (gaps.filter((g) => g > 0.3).length / totalDuration) * 100,
            ) / 100,
          avgConfidence: Math.round(
            (words.reduce((s, w) => s + (w.probability || 0), 0) /
              words.length) *
            100,
          ),
        };
      }

      // Save audio permanently in uploads/audio/
      const audioDir = path.join(__dirname, "..", "uploads", "audio");
      if (!fs.existsSync(audioDir)) {
        fs.mkdirSync(audioDir, { recursive: true });
      }
      const ext = path.extname(req.file.originalname) || ".wav";
      const filename = `user_${crypto.randomUUID()}${ext}`;
      const destPath = path.join(audioDir, filename);
      fs.copyFileSync(req.file.path, destPath);
      audioUrl = `/api/interview/uploads/audio/${filename}`;

      // Clean up temp file from multer
      fs.unlinkSync(req.file.path);
    }

    if (!message) {
      return res
        .status(400)
        .json({ success: false, message: "No message or audio provided." });
    }

    const history = req.body.history
      ? typeof req.body.history === "string"
        ? JSON.parse(req.body.history)
        : req.body.history
      : [];
    const roleTitle = req.body.roleTitle || "";

    // Construct the detailed system prompt
    const systemPrompt = `You are Thomas Lefebvre, an experienced hiring manager conducting a realistic job interview.

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
    * IMPORTANT: You must write your ENTIRE response strictly in ${langString}. If the candidate uses English technical terms, TRANSLATE them into ${langString} or adapt them naturally so the text is 100% ${langString}.
    * CRITICAL: Always finish your sentences and ensure the thought is complete.`;

    // Map frontend history to Groq format
    const formattedHistory = history.map((msg) => ({
      role: msg.isUser ? "user" : "assistant",
      content: msg.text,
    }));

    // Determine the actual user message text for the chat display
    const userMessageText = req.file ? message || "(message vocal)" : message;

    const chatCompletion = await groq.chat.completions.create({
      messages: [
        { role: "system", content: systemPrompt },
        ...formattedHistory,
        { role: "user", content: message },
      ],
      model: "llama-3.3-70b-versatile",
      temperature: 0.7,
      max_tokens: 500,
    });

    const aiResponse =
      chatCompletion.choices[0]?.message?.content ||
      "C'est intéressant. Pourriez-vous détailler un peu plus ?";
    const audioBase64 = await generateAudio(aiResponse, langCode);

    res.status(200).json({
      success: true,
      reply: aiResponse,
      audioBase64: audioBase64,
      userTranscript: message,
      audioUrl: audioUrl,
      vocalMetrics: vocalMetrics,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Preprocess interview answers to compute speech fluency metrics( arije str 1)
function analyzeSpeechFluency(history) {
  const candidateMessages = history.filter((msg) => msg.isUser);
  const totalCandidateMessages = candidateMessages.length;

  if (totalCandidateMessages === 0) {
    return {
      fillerCount: 0,
      repetitionCount: 0,
      pauseCount: 0,
      wordsPerMinute: 0,
      averageResponseLength: 0,
      hesitationScore: 0,
    };
  }

  let fillerCount = 0;
  let wordCount = 0;
  let repetitionCount = 0;
  let pauseCount = 0;

  // Common French filler words and sounds
  const fillers = [
    "euh",
    "hmm",
    "mmm",
    "ben",
    "bah",
    "en fait",
    "genre",
    "tu vois",
    "fin",
    "donc",
    "alors",
  ];
  const pauses = ["...", "…"];

  candidateMessages.forEach((msg) => {
    // Ensure text exists
    const text = (msg.text || "").toLowerCase();

    // Count words (basic space separation)
    const words = text.split(/\s+/).filter((w) => w.length > 0);
    wordCount += words.length;

    // Count fillers
    fillers.forEach((filler) => {
      // Use regex to match whole words for fillers(str1 arije)
      const regex = new RegExp(`\\b${filler}\\b`, "g");
      const matches = text.match(regex);
      if (matches) fillerCount += matches.length;
    });

    // Count pauses (approximate by counting ellipses de la 1 str)
    pauses.forEach((pause) => {
      const matches = text.split(pause).length - 1;
      pauseCount += matches;
    });

    // Count repetitions (str2 rija)
    for (let i = 0; i < words.length - 1; i++) {
      if (words[i] === words[i + 1] && words[i].length > 1) {
        repetitionCount++;
      }
    }
  });

  const averageResponseLength = Math.round(wordCount / totalCandidateMessages);

  // Hesitation score (0-100) based on fillers + pauses + repetitions per 100 words
  const hesitationIndicators = fillerCount + pauseCount + repetitionCount;
  // If hesitation indicators equal 10% of total words, score is ~50.

  // Aggregate real vocal metrics from audio recordings
  const userMessages = history.filter((msg) => msg.isUser && msg.vocalMetrics);
  let vocalAggMetrics = null;
  if (userMessages.length > 0) {
    const total = userMessages.length;
    const sumWpm = userMessages.reduce(
      (s, m) => s + (m.vocalMetrics.wordsPerMinute || 0),
      0,
    );
    const sumPause = userMessages.reduce(
      (s, m) => s + (m.vocalMetrics.avgPauseMs || 0),
      0,
    );
    const sumLongPauses = userMessages.reduce(
      (s, m) => s + (m.vocalMetrics.longPauses || 0),
      0,
    );
    const sumPauseRate = userMessages.reduce(
      (s, m) => s + (m.vocalMetrics.pauseRate || 0),
      0,
    );
    const sumConfidence = userMessages.reduce(
      (s, m) => s + (m.vocalMetrics.avgConfidence || 0),
      0,
    );
    const sumDuration = userMessages.reduce(
      (s, m) => s + (m.vocalMetrics.totalDuration || 0),
      0,
    );

    vocalAggMetrics = {
      fillerCount: fillerCount,
      repetitionCount: repetitionCount,
      pauseCount: Math.round(sumLongPauses),
      wordsPerMinute: Math.round(sumWpm / total),
      averageResponseLength: Math.round(wordCount / totalCandidateMessages),
      hesitationScore: Math.min(
        100,
        Math.round(
          sumPause / total / 20 +
          (sumPauseRate / total) * 50 +
          (50 - sumConfidence / total),
        ),
      ),
      // Audio-specific
      avgPauseMs: Math.round(sumPause / total),
      totalLongPauses: sumLongPauses,
      avgPauseRate: Math.round((sumPauseRate / total) * 100) / 100,
      avgConfidence: Math.round(sumConfidence / total),
      totalSpeechDuration: Math.round(sumDuration * 100) / 100,
      numResponses: total,
    };
  }

  return (
    vocalAggMetrics || {
      fillerCount,
      repetitionCount,
      pauseCount,
      wordsPerMinute: wordsPerMinute > 0 ? wordsPerMinute : 120, // default average if 0
      averageResponseLength,
      hesitationScore,
    }
  );
}

exports.finishSimulation = async (req, res) => {
  try {
    const { history = [], roleTitle } = req.body;

    if (history.length === 0) {
      return res
        .status(400)
        .json({
          success: false,
          message: "No conversation history provided for evaluation.",
        });
    }

    const candidateMessages = history.filter((msg) => msg.isUser);
    const candidateWordCount = candidateMessages.reduce(
      (count, msg) =>
        count + (msg.text ? msg.text.trim().split(/\s+/).length : 0),
      0,
    );

    if (candidateMessages.length === 0 || candidateWordCount < 5) {
      return res.status(200).json({
        success: true,
        globalScore: 0,
        score: 0,
        emotionalState: "Non évaluable",
        starAnalysis: {
          overallScore: 0,
          situation: 0,
          task: 0,
          action: 0,
          result: 0,
          missingElements: [
            "Aucune réponse suffisante du candidat pour appliquer la méthode STAR.",
          ],
        },
        personality: {
          openness: 0,
          conscientiousness: 0,
          extraversion: 0,
          agreeableness: 0,
          emotionalStability: 0,
        },
        speechAnalysis: {
          confidence: 0,
          stress: 0,
          calmness: 0,
          uncertainty: 0,
          fluencyFeedback: "Pas de discours détecté ou discours trop court.",
          metrics: {
            fillerCount: 0,
            repetitionCount: 0,
            pauseCount: 0,
            wordsPerMinute: 0,
            averageResponseLength: 0,
            hesitationScore: 0,
          },
        },
        skills: { clarity: 0, relevance: 0, structure: 0 },
        analysis: {
          stressLevel: 0,
          selfConfidence: 0,
          clarity: 0,
          engagement: 0,
        },
        strengths: ["Aucun point fort détecté (entretien vide ou trop court)."],
        improvements: [
          {
            title: "Participation",
            description:
              "Il est nécessaire de répondre aux questions pour être évalué.",
          },
          {
            title: "Communication",
            description: "Assurez-vous que votre microphone fonctionne.",
          },
          {
            title: "Engagement",
            description: "Participez activement à l'échange.",
          },
          {
            title: "Contenu",
            description: "Fournissez des réponses détaillées.",
          },
        ],
      });
    }

    const transcript = history
      .map((msg) => `${msg.isUser ? "Candidat" : "Recruteur"}: ${msg.text}`)
      .join("\n");

    // Speech fluency from audio recordings (vocal metrics override text-based)
    const speechMetrics = analyzeSpeechFluency(history);

    const evaluationPrompt = `You are an expert HR evaluator, organizational psychologist, and linguist. 
    Review the following job interview transcript for a ${roleTitle} position.
    You have the following REAL vocal/audio metrics extracted from the candidate's voice recordings using Whisper AI (word-level timestamps + confidence):
    ${JSON.stringify(speechMetrics, null, 2)}

    These metrics are based on actual audio analysis:
    - wordsPerMinute: Speaking pace (slow < 120, normal 120-160, fast > 160)
    - avgPauseMs: Average gap between words in milliseconds (low = fluent, high = hesitant)
    - totalLongPauses: Number of pauses > 0.5s (high = hesitation, uncertainty)
    - avgConfidence: Whisper's confidence in recognizing words (0-100, low = mumbling/unclear speech)
    - hesitationScore: Composite from audio data (0 = fluent, 100 = highly hesitant)
    - pauseRate: Pauses per second of speech (high = disjointed delivery)

    Use these audio metrics to infer the candidate's emotional state, confidence, stress level, and vocal delivery. Then evaluate the CONTENT of their answers using STAR method and Big Five personality traits.

    Based on the candidate's answers AND vocal metrics, provide a detailed psychometric and professional evaluation in JSON format exactly matching this structure:
    {
      "globalScore": <number out of 100>,
      "score": <number out of 100>,
      "emotionalState": "<a brief string describing the emotional state e.g., 'Confiant', 'Stressé', 'Calme'>",
      "starAnalysis": {
        "overallScore": <number out of 100>,
        "situation": <number out of 100>,
        "task": <number out of 100>,
        "action": <number out of 100>,
        "result": <number out of 100>,
        "missingElements": ["<Array of strings describing missing STAR elements, e.g., 'Le résultat concret manquait'>"]
      },
      "personality": {
        "openness": <number out of 100>,
        "conscientiousness": <number out of 100>,
        "extraversion": <number out of 100>,
        "agreeableness": <number out of 100>,
        "emotionalStability": <number out of 100>
      },
      "speechAnalysis": {
        "confidence": <number out of 100>,
        "stress": <number out of 100>,
        "calmness": <number out of 100>,
        "uncertainty": <number out of 100>,
        "fluencyFeedback": "<A short sentence in French summarizing their speech fluency based on the metrics>"
      },
      "skills": {
        "clarity": <number out of 100>,
        "relevance": <number out of 100>,
        "structure": <number out of 100>
      },
      "analysis": {
        "stressLevel": <number out of 100>,
        "selfConfidence": <number out of 100>,
        "clarity": <number out of 100>,
        "engagement": <number out of 100>
      },
      "strengths": ["<Array of exactly 3 strong points>"],
      "improvements": [
        {
          "title": "<Short title of improvement>",
          "description": "<Detailed description and example of a better answer for one of the weak responses>"
        }
      ]
    }

    Requirements:
    - The improvements array must have EXACTLY 4 items.
    - All text responses MUST be in French.
    - CRITICAL: Base your emotionalState, speechAnalysis (confidence, stress, calmness, uncertainty), and personality (extraversion, emotionalStability) primarily on the VOCAL METRICS above, not just the transcript text. Example: long pauses + low confidence + slow WPM → high stress, low confidence. Fast WPM + high confidence + few pauses → confident, calm.
    - STRICT GRADING: If the candidate gives nonsensical, bizarre, irrelevant, or "troll" answers, you MUST heavily penalize the globalScore, score, and all skill scores, pushing them close to 0-20. Do NOT give a default passing score (like 60-70) for bad or irrelevant answers Else continue with the analysis we agreed on.
    - Provide ONLY raw JSON without markdown formatting like \`\`\`json.

    Transcript:
    ${transcript}`;

    const chatCompletion = await groq.chat.completions.create({
      messages: [
        { role: "system", content: "You output raw JSON only." },
        { role: "user", content: evaluationPrompt },
      ],
      model: "llama-3.3-70b-versatile",
      temperature: 0.2,
      max_tokens: 1500,
    });

    let evaluationData;
    try {
      const responseText = chatCompletion.choices[0]?.message?.content || "{}";

      const cleanedText = responseText
        .replace(/```json/g, "")
        .replace(/```/g, "")
        .trim();
      evaluationData = JSON.parse(cleanedText);
      evaluationData.isFallback = false;

      // Merge in our computed speech metrics for completeness in the final output
      if (evaluationData.speechAnalysis) {
        evaluationData.speechAnalysis.metrics = speechMetrics;
      } else {
        evaluationData.speechAnalysis = { metrics: speechMetrics };
      }

      // Hardcap the score if the candidate hasn't spoken enough words
      if (candidateWordCount < 100) {
        evaluationData.globalScore = Math.min(evaluationData.globalScore || 0, 50);
        evaluationData.score = Math.min(evaluationData.score || 0, 50);
        if (evaluationData.starAnalysis) {
          evaluationData.starAnalysis.overallScore = Math.min(evaluationData.starAnalysis.overallScore || 0, 50);
        }
      }
    } catch (e) {
      console.error("Failed to parse AI evaluation:", e);
      // Fallback representing the new comprehensive structure
      evaluationData = {
        isFallback: true,
        globalScore: 70,
        score: 70,
        emotionalState: "Neutre",
        starAnalysis: {
          overallScore: 65,
          situation: 70,
          task: 70,
          action: 60,
          result: 60,
          missingElements: [
            "Manque de résultats quantifiables",
            "L'action n'est pas toujours détaillée",
          ],
        },
        personality: {
          openness: 60,
          conscientiousness: 75,
          extraversion: 65,
          agreeableness: 70,
          emotionalStability: 60,
        },
        speechAnalysis: {
          confidence: 65,
          stress: 40,
          calmness: 60,
          uncertainty: 30,
          fluencyFeedback:
            "Le discours manque parfois de fluidité, avec quelques hésitations et répétitions.",
          metrics: speechMetrics,
        },
        skills: { clarity: 70, relevance: 75, structure: 65 },
        analysis: {
          stressLevel: 40,
          selfConfidence: 65,
          clarity: 70,
          engagement: 75,
        },
        strengths: [
          "Bonne compréhension du poste",
          "Attitude professionnelle",
          "Connaissances techniques adéquates",
        ],
        improvements: [
          {
            title: "Méthode STAR",
            description:
              "Structurez vos réponses en détaillant la situation, la tâche, l'action et le résultat concret.",
          },
          {
            title: "Réduire les hésitations",
            description:
              "Prenez une courte pause avant de répondre au lieu d'utiliser des mots de remplissage.",
          },
          {
            title: "Quantifier les succès",
            description:
              "Apportez des chiffres et des metrics pour prouver vos résultats.",
          },
          {
            title: "Confiance en soi",
            description:
              "Adoptez un ton plus affirmatif lors de la description de vos réussites.",
          },
        ],
      };
    }

    const finalData = {
      success: true,
      ...evaluationData,
    };

    if (req.body.candidateId) {
      try {
        console.log(
          "Attempting to save interview history for candidateId:",
          req.body.candidateId,
        );
        const InterviewHistory = require("../models/InterviewHistory");
        const conversation = history.map((msg) => ({
          role: msg.isUser ? "user" : "assistant",
          text: msg.text || "",
          audioUrl: msg.audioUrl || null,
          vocalMetrics: msg.vocalMetrics || null,
        }));
        const historyRecord = new InterviewHistory({
          candidateId: req.body.candidateId,
          roleTitle: roleTitle,
          globalScore: evaluationData.globalScore || evaluationData.score,
          emotionalState: evaluationData.emotionalState,
          analysis: evaluationData,
          conversation: conversation,
        });
        await historyRecord.save();
        console.log(
          "Successfully saved interview history! ID:",
          historyRecord._id,
        );
      } catch (err) {
        console.error("Failed to save interview history:", err);
      }
    } else {
      console.log("No candidateId provided, skipping history save.");
    }

    res.status(200).json(finalData);
  } catch (error) {
    console.error("Finish simulation error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getHistory = async (req, res) => {
  try {
    const { candidateId } = req.params;
    console.log("Fetching interview history for candidateId:", candidateId);
    const InterviewHistory = require("../models/InterviewHistory");
    const history = await InterviewHistory.find({ candidateId }).sort({
      createdAt: -1,
    });
    console.log(
      `Found ${history.length} history records for candidateId:`,
      candidateId,
    );
    res.status(200).json({ success: true, history });
  } catch (error) {
    console.error("Error fetching history:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};
