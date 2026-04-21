const express = require('express');
const router = express.Router();
const { getProfile, updateProfile, getDashboardData, getFormations, seedDummyData, suggestExpertise, generateBio, validateUrl } = require('../controllers/formateurController');

router.route('/profile/:userId').get(getProfile).put(updateProfile);
router.route('/dashboard/:userId').get(getDashboardData);
router.route('/formations/:userId').get(getFormations);
router.route('/seed/:userId').post(seedDummyData);
router.route('/suggest-expertise').post(suggestExpertise);
router.route('/generate-bio').post(generateBio);
router.route('/validate-url').post(validateUrl);

module.exports = router;
