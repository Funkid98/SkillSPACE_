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

const matchCvWithJob = async (cvText, jobDescription) => {
  const response = await groq.chat.completions.create({
    model: 'llama-3.3-70b-versatile',
    messages: [
      {
        role: 'system',
        content: `Tu es un expert en recrutement. Ton analyse et le calcul du score de compatibilité doivent se baser UNIQUEMENT SUR LES COMPÉTENCES REQUISES (Skills_Required) du poste, en ignorant le reste.
        Réponds UNIQUEMENT en JSON (pas de texte avant ou après, pas de markdown) avec ces champs :
        1. matching_analysis: Une description de 2-3 phrases expliquant la pertinence du candidat selon les compétences. NE FAIS PAS de liste. L'analyse doit suivre ce format narratif précis : "Le candidat a une expérience pertinente en tant qu'IT Support Intern et a développé des compétences en matière de résolution de problèmes et de maintenance de systèmes. Il a également une bonne compréhension des principes de sécurité et de réseau. Cependant, il lui manque certaines compétences spécifiques pour le poste d'IT Specialist, telles que l'expérience avec les services cloud et les bases de données avancées."
        2. recommendation: Formations spécifiques (ex: 'Certification AWS sur Notre Platforme avec le formatteur X') pour les compétences manquantes.
        3. score: Score de compatibilité (0-100) basé EXCLUSIVEMENT sur les Skills_Required.
        4. matched_skills: Liste des noms des compétences trouvées qui correspondent aux 'Skills_Required' du poste.
        5. missing_skills: Liste EXACTE des compétences manquantes, basées EXCLUSIVEMENT sur les 'Skills_Required' demandés dans le poste. Ne génère pas de compétences qui ne sont pas explicitement exigées.`
      },
      {
        role: 'user',
        content: `CV: ${cvText}\n\nPOSTE: ${jobDescription}`
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

module.exports = { extractSkillsFromText, matchCvWithJob }