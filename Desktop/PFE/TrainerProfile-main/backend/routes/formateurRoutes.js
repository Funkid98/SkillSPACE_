const express = require('express');
const router = express.Router();
const {
  getProfile, updateProfile, patchProfile, getDashboardData, getFormations,
  getAllFormations, seedDummyData, suggestExpertise, generateBio, validateUrl,
  createFormation, updateFormation, deleteFormation, enhanceFormation,
  register, login, verifySignupOtp, checkEmailExists, enrollFormation, getFormationById
} = require('../controllers/formateurController');

router.route('/profile/:userId').get(getProfile).put(updateProfile).patch(patchProfile);
router.route('/dashboard/:userId').get(getDashboardData);

// Auth Routes
router.post('/register', register);
router.post('/login', login);
router.post('/verify-signup', verifySignupOtp);
router.get('/exists/:email', checkEmailExists);



// Formation Management
router.route('/formations/:userId').get(getFormations).post(createFormation);
router.route('/formations/item/:id').get(getFormationById).put(updateFormation).delete(deleteFormation);
router.post('/formations/item/:id/enroll', enrollFormation);
router.get('/all-formations', getAllFormations);
router.route('/seed/:userId').post(seedDummyData);
router.route('/suggest-expertise').post(suggestExpertise);
router.route('/generate-bio').post(generateBio);
router.route('/validate-url').post(validateUrl);
router.route('/enhance-formation').post(enhanceFormation);

module.exports = router;
