const express = require('express');
const router = express.Router();
const { 
    createOffer, 
    updateOffer, 
    deleteOffer, 
    getRecruiterOffers, 
    getMatchingOffers, 
    getOffers,
    incrementView
} = require('../controllers/offer.controller');
const { protect } = require('../middleware/auth-middleware');

router.route('/')
    .get(getOffers)
    .post(protect, createOffer);

router.get('/my-offers', protect, getRecruiterOffers);
router.get('/matches', getMatchingOffers);

router.route('/:id')
    .put(protect, updateOffer)
    .delete(protect, deleteOffer);

router.put('/:id/view', incrementView);

module.exports = router;
