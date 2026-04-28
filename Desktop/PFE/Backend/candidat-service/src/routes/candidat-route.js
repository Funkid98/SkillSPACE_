const express = require('express')
const router = express.Router()
const { register, login, getProfile, updateProfile, getRecentCandidatesBySector, getMatchingOffersForCandidate, getMatchingCandidatesGroupedByOffer, reMatchOffer, applyToOffer, receiveNotification, getNotifications, markNotificationRead, internalUpdateApplication, deleteNotification, clearAllNotifications } = require('../controllers/candidat-controller')
const auth = require('../middleware/auth-middleware')


router.post('/register', register)
router.post('/login', login)


router.get('/me', auth, getProfile)
router.put('/me', auth, updateProfile)
router.get('/recent/:sector', auth, getRecentCandidatesBySector)
router.get('/matching-offers', auth, getMatchingOffersForCandidate)
router.get('/grouped-matches', auth, getMatchingCandidatesGroupedByOffer)

// Internal route for offer-service to trigger re-matching after job update
router.post('/trigger-match/offer/:id', reMatchOffer)

// Application & Notifications
router.post('/apply', auth, applyToOffer)
router.post('/internal/application/update', internalUpdateApplication)
router.post('/internal/notify', receiveNotification) // Called by recruter-service
router.get('/notifications', auth, getNotifications)
router.put('/notifications/:id/read', auth, markNotificationRead)
router.delete('/notifications/:id', auth, deleteNotification)
router.delete('/notifications/clear/all', auth, clearAllNotifications)
router.get('/internal/:id', async (req, res) => {
    const User = require('../models/candidat')
    const user = await User.findById(req.params.id).select('-password')
    if (!user) return res.status(404).json({ error: 'Not found' })
    res.json(user)
})

module.exports = router