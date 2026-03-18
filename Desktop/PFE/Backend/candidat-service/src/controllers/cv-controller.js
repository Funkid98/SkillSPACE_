const { extractText } = require('../services/extractor');
const { extractSkillsFromText } = require('../services/ai-service');
const User = require('../models/candidat');

const uploadCv = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: 'No file' });

    const text = await extractText(req.file.buffer, req.file.originalname);
    const cvData = await extractSkillsFromText(text);

    if (!cvData) throw new Error('AI extraction failed');

    console.log('CV Data extracted:', cvData);
    console.log('User ID from token:', req.userId);

    if (req.userId) {
      const updates = {
        prenom: cvData.prenom,
        nom: cvData.nom,
        telephone: cvData.telephone,
        jobtitle: cvData.jobTitle,
        localisation: cvData.localisation,
        bio: cvData.bio,
        skills: cvData.skills?.map(s => typeof s == 'string' ? s : s.name),
        cv_path: req.file.originalname,
        completion_percent: 100
      };
      console.log('Applying updates to DB:', updates);
      const updatedUser = await User.findByIdAndUpdate(req.userId, { $set: updates }, { new: true });
      console.log('Update result:', updatedUser ? 'User updated successfully' : 'User not found');
    }

    res.json({ success: true, data: cvData });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

module.exports = { uploadCv };
