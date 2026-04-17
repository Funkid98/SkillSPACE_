const Formateur = require('../models/formateurModel');

// @desc    Get formateur profile
// @route   GET /api/formateur/profile/:userId
const getProfile = async (req, res) => {
  try {
    const formateur = await Formateur.findOne({ userId: req.params.userId });
    if (!formateur) {
      return res.status(404).json({ message: 'Profil non trouvé' });
    }
    res.status(200).json(formateur);
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message });
  }
};

// @desc    Create or Update formateur profile
// @route   PUT /api/formateur/profile/:userId
const updateProfile = async (req, res) => {
  try {
    const { userId } = req.params;
    const updateData = req.body;
    
    // Calculate profile completeness roughly
    let completeness = 0;
    if (updateData.firstName && updateData.lastName) completeness += 20;
    if (updateData.email) completeness += 10;
    if (updateData.bio) completeness += 20;
    if (updateData.profilePicture) completeness += 20;
    if (updateData.expertise && updateData.expertise.length > 0) completeness += 15;
    if (updateData.certifications && updateData.certifications.length > 0) completeness += 15;
    
    updateData.profileCompleteness = Math.min(completeness, 100);

    const formateur = await Formateur.findOneAndUpdate(
      { userId },
      updateData,
      { new: true, upsert: true, runValidators: true }
    );
    
    res.status(200).json(formateur);
  } catch (error) {
    res.status(500).json({ message: 'Erreur lors de la mise à jour', error: error.message });
  }
};

module.exports = {
  getProfile,
  updateProfile
};
