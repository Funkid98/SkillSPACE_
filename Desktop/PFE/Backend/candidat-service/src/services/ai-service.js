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

module.exports = { extractSkillsFromText }