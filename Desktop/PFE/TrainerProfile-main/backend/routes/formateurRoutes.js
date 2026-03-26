const express = require('express');
const router = express.Router();
const { getProfile, updateProfile } = require('../controllers/formateurController');

router.route('/profile/:userId').get(getProfile).put(updateProfile);

module.exports = router;
