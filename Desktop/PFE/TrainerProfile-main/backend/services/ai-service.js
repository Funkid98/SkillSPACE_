const Groq = require('groq-sdk');

/**
 * Suggest expertise domains for a formateur using Groq Llama 4 Scout.
 * @param {string} query - The partial text the user typed.
 * @param {string[]} existing - Already selected domains to exclude.
 * @returns {Promise<string[]>} - Array of suggested domain names.
 */
const suggestExpertiseDomains = async (query, existing = []) => {
  const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

  const existingList =
    existing.length > 0
      ? `Domaines déjà sélectionnés (ne pas les répéter): ${existing.join(', ')}.`
      : '';

  const response = await groq.chat.completions.create({
    model: 'meta-llama/llama-4-scout-17b-16e-instruct',
    messages: [
      {
        role: 'system',
        content: `You are an assistant for professional trainers on an e-learning platform.
        Generate relevant professional expertise domain suggestions in French based on the user's input.
        ${existingList}
        Strict rules:
        - Return ONLY a valid JSON array, no markdown, no text before or after.
        - 5 to 8 suggestions maximum, relevant and precise.
        - Examples of domains: "Intelligence Artificielle", "Développement Web", "Data Science", "Cybersécurité", "Cloud Computing", "UX/UI Design", "Marketing Digital", "Gestion de Projet", "DevOps", "Blockchain", "Mobile Development", "Réseaux & Systèmes".
        - Avoid suggesting domains that are already selected.
        - Suggestions must relate to or start with the user's input.
        - Expected format: ["Suggestion 1", "Suggestion 2", "Suggestion 3"]`,
      },
      {
        role: 'user',
        content: `User input: "${query.trim()}"`,
      },
    ],
    temperature: 0.4,
    max_tokens: 200,
  });

  const raw = response.choices[0].message.content.trim();
  const clean = raw.replace(/```json|```/g, '').trim();
  const suggestions = JSON.parse(clean);
  return Array.isArray(suggestions) ? suggestions : [];
};

/**
 * Generate a professional bio for a formateur.
 * @param {string} name - Trainer's name.
 * @param {string} jobTitle - Trainer's professional title.
 * @param {string[]} expertise - List of expertise domains.
 * @returns {Promise<string>} - Generated biography.
 */
const generateBioValue = async (name, jobTitle, expertise = []) => {
  const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

  const response = await groq.chat.completions.create({
    model: 'meta-llama/llama-4-scout-17b-16e-instruct',
    messages: [
      {
        role: 'system',
        content: `You are a professional profile optimizer for an e-learning platform.
        Write a concise, engaging, and professional 3-sentence biography in French for a trainer.
        Rules:
        - Speak in the FIRST PERSON ("Je suis...", "J'accompagne...").
        - Highlight the expertise domains provided.
        - Maintain a tone of authority and passion.
        - Maximum 300 characters.
        - Return ONLY the biography text, no introduction, no quotes.`,
      },
      {
        role: 'user',
        content: `Name: ${name}, Job Title: ${jobTitle}, Expertise: ${expertise.join(', ')}`,
      },
    ],
    temperature: 0.7,
    max_tokens: 200,
  });

  return response.choices[0].message.content.trim();
};

/**
 * Validate if a URL is a professional portfolio/personal website vs a generic platform.
 * @param {string} url - The URL to validate.
 * @returns {Promise<{isValid: boolean, reason: string}>}
 */
const validatePortfolioUrlAI = async (url) => {
  const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

  const response = await groq.chat.completions.create({
    model: 'meta-llama/llama-4-scout-17b-16e-instruct',
    messages: [
      {
        role: 'system',
        content: `You are a URL verification assistant for a professional training platform.
        Determine if the given URL is a professional personal portfolio, a personal resume site, a GitHub profile, or a professional blog.
        Reject URLs that are generic major platforms (google.com, amazon.com, etc.), generic search results, or social media landing pages that aren't professional profiles.
        
        Strict rules:
        - Return ONLY a JSON object: {"isValid": boolean, "reason": "short explanation in French"}.
        - If invalid, provide a polite reason why.
        - LinkedIn is handled separately, so if the URL is LinkedIn, return {"isValid": false, "reason": "Veuillez utiliser le champ LinkedIn dédié."}.`,
      },
      {
        role: 'user',
        content: `URL: ${url}`,
      },
    ],
    temperature: 0.2,
    max_tokens: 150,
  });

  const raw = response.choices[0].message.content.trim();
  const clean = raw.replace(/```json|```/g, '').trim();
  try {
    return JSON.parse(clean);
  } catch (e) {
    return { isValid: true, reason: '' }; // Fallback
  }
};

module.exports = {
  suggestExpertiseDomains,
  generateBio: generateBioValue,
  validatePortfolioUrlAI
};
